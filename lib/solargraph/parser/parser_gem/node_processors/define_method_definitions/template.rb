# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        module DefineMethodDefinitions
          # What a method defines when it calls define_method or
          # define_singleton_method with a name taken from one of its own
          # parameters, e.g., ActionController's
          #
          #   def add_flash_types(*types)
          #     types.each { |type| define_method(type) { request.flash[type] } }
          #   end
          #
          # A call to the method with literal names, e.g., +add_flash_types :alert+,
          # generates the methods it defines.
          #
          # Only the method's own parameters are followed, either directly or
          # through +param.each { |name| ... }+, and only Symbol and String
          # literals in the call's arguments produce names.
          class Template
            # The methods that define a method and the scope of the methods they
            # define when called at class level.
            DEFINERS = { define_method: :instance, define_singleton_method: :class }.freeze

            # Parameter node types and their Pin::Parameter declarations
            PARAMETER_DECLS = {
              arg: :arg, optarg: :optarg, restarg: :restarg, kwarg: :kwarg,
              kwoptarg: :kwoptarg, kwrestarg: :kwrestarg, blockarg: :blockarg
            }.freeze

            # The parameters given to a defined method whose body is not a literal
            # block, e.g., +define_method(name, &block)+
            UNKNOWN_PARAMETERS = [[:restarg, 'args'], [:kwrestarg, 'kwargs'], [:blockarg, 'block']].freeze

            # The number of leading parameters a template's names can come from,
            # which bounds the work per define_method call and the summaries per
            # method
            MAX_POSITIONS = 16

            # The number of blocks around a define_method call that are searched
            # for the method's body, which bounds the work per call
            MAX_BLOCK_DEPTH = 16

            # @return [Integer] the position of the argument that supplies names
            attr_reader :position

            # @return [::Symbol] :name if the argument is a name, :splat if every
            #   argument from the position onward is a name, :array if the argument
            #   is an array of names
            attr_reader :mode

            # @return [::Symbol] :instance or :class
            attr_reader :scope

            # @return [::Array<::Array(::Symbol, String)>] the declarations and names
            #   of the defined method's parameters
            attr_reader :parameters

            # @param position [Integer]
            # @param mode [::Symbol]
            # @param scope [::Symbol]
            # @param parameters [::Array<::Array(::Symbol, String)>]
            def initialize position:, mode:, scope:, parameters:
              @position = position
              @mode = mode
              @scope = scope
              @parameters = parameters
            end

            # @param other [Object]
            def == other
              other.is_a?(Template) && to_a == other.to_a
            end

            alias eql? ==

            # @return [Integer]
            def hash
              to_a.hash
            end

            # @return [::Array(Integer, ::Symbol, ::Symbol, ::Array<::Array(::Symbol, String)>)]
            def to_a
              [position, mode, scope, parameters]
            end

            # Templates with the same key generate methods with the same names.
            #
            # @return [::Array(Integer, ::Symbol, ::Symbol)]
            def key
              [position, mode, scope]
            end

            # The methods a call to the template's method generates.
            #
            # @param call [::Parser::AST::Node] the send node that calls the method
            # @param closure [Pin::Namespace] the namespace the call is made in
            # @param location [Location] the call's location
            # @return [::Array<Pin::Method>]
            def generate_pins call, closure, location
              names_from(call).map do |name|
                pin = Pin::Method.new(location: location, closure: closure, name: name, scope: scope,
                                      visibility: :public, source: :parser)
                parameters.each do |decl, param_name|
                  pin.parameters.push Pin::Parameter.new(name: param_name, decl: decl, closure: pin, source: :parser)
                end
                pin
              end
            end

            class << self
              # The template that a define_method call makes of the method whose
              # body contains it, if any.
              #
              # @param send [::Parser::AST::Node] a send node
              # @param def_node [::Parser::AST::Node, nil] the def or defs node
              #   whose body contains the call
              # @param blocks [::Array<::Parser::AST::Node>] the block nodes in the
              #   method that contain the call, outermost first
              # @return [Template, nil]
              def from_send send, def_node, blocks
                return nil unless definer?(send)
                # s(:def, name, args, body) or s(:defs, receiver, name, args, body)
                args = if def_node in [:def, _, ::Parser::AST::Node => def_args, *]
                         def_args
                       elsif def_node in [:defs, _, _, ::Parser::AST::Node => defs_args, *]
                         defs_args
                       end
                return nil if args.nil?
                positions = positional_parameters(args)
                return nil if positions.empty?
                # @type [Hash{::Symbol => ::Symbol}]
                each_vars = {}
                blocks.each { |block| each_vars.update(each_variable(block, positions)) }
                # s(:block, call, args, body), when the block is define_method's own
                block_args = nil
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                if (blocks.last in [_, call, block_params, *]) && call.equal?(send)
                  block_args = block_params
                end
                build send, positions, each_vars, block_args
              end

              private

              # The method's positional parameters up to and including a rest
              # parameter, which maps every argument after it.
              #
              # @param args [::Parser::AST::Node]
              # @return [Hash{::Symbol => ::Array(Integer, ::Symbol)}] name => [position, type]
              def positional_parameters args
                # @type [Hash{::Symbol => ::Array(Integer, ::Symbol)}]
                result = {}
                return result unless Parser.is_ast_node?(args)
                args.children.take(MAX_POSITIONS).each_with_index do |arg, index|
                  # s(:arg, name), s(:optarg, name, default) or s(:restarg, name)
                  break unless arg in [:arg | :optarg | :restarg => type, Symbol => param, *]
                  result[param] = [index, type]
                  # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                  break if type == :restarg
                end
                result
              end

              # @param node [::Parser::AST::Node]
              # @return [Boolean]
              def definer? node
                # define_method(name) - s(:send, nil, :define_method, name, *args)
                return false unless node in [:send, nil | [:self], Symbol => method_name, *]
                DEFINERS.key?(method_name)
              end

              # The block variable of +param.each { |var| ... }+, mapped to +param+.
              #
              # @param node [::Parser::AST::Node] a block node
              # @param positions [Hash{::Symbol => ::Array(Integer, ::Symbol)}]
              # @return [Hash{::Symbol => ::Symbol}]
              def each_variable node, positions
                # s(:block, s(:send, s(:lvar, param), :each), s(:args, arg), body)
                return {} unless node in [_, [:send, [:lvar, Symbol => param], :each], [:args, arg], *]
                return {} unless positions.key?(param)
                var = block_variable(arg)
                var ? { var => param } : {}
              end

              # @param arg [::Parser::AST::Node, nil]
              # @return [::Symbol, nil]
              def block_variable arg
                # |var| - s(:arg, var); a lone |var| - s(:procarg0, s(:arg, var)) or s(:procarg0, var)
                if arg in [:procarg0, ::Parser::AST::Node => inner]
                  block_variable(inner)
                elsif arg in [:arg | :procarg0, Symbol => var]
                  var
                end
              end

              # @param send [::Parser::AST::Node] the define_method call
              # @param positions [Hash{::Symbol => ::Array(Integer, ::Symbol)}]
              # @param each_vars [Hash{::Symbol => ::Symbol}]
              # @param block_args [::Parser::AST::Node, nil] the defined method's
              #   parameters, if its body is a literal block
              # @return [Template, nil]
              def build send, positions, each_vars, block_args
                # define_method(var) - s(:send, receiver, method_name, s(:lvar, var), *args)
                send => [:send, _, Symbol => method_name, *args]
                return nil unless args in [[:lvar, Symbol => var], *]
                iterated = each_vars[var]
                param = positions[iterated || var]
                return nil if param.nil?
                position, type = param
                if iterated
                  mode = type == :restarg ? :splat : :array
                else
                  return nil if type == :restarg
                  mode = :name
                end
                new(position: position, mode: mode, scope: DEFINERS.fetch(method_name),
                    parameters: block_parameters(block_args))
              end

              # @param args [::Parser::AST::Node, nil]
              # @return [::Array<::Array(::Symbol, String)>]
              def block_parameters args
                return UNKNOWN_PARAMETERS if args.nil?
                args.children.filter_map do |arg|
                  variable = block_variable(arg)
                  next [:arg, variable.to_s] if (arg in [:procarg0, *]) && variable
                  # s(:optarg, name, default); s(:restarg) for a bare *
                  arg => [Symbol => type, *rest]
                  decl = PARAMETER_DECLS[type]
                  # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                  [decl, rest.first.to_s] if decl
                end
              end
            end

            private

            # @param call [::Parser::AST::Node]
            # @return [::Array<String>]
            def names_from call
              # s(:send, receiver, method_name, *args)
              call => [:send, _, _, *call_args]
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              args = call_args.reject { |arg| arg in [:block_pass, *] }
              # A trailing hash is keyword arguments, not a name
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              args.pop if args.last in [:hash, *]
              # Splatted arguments make the positions unknowable
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              return [] if args.take(position + 1).any? { |arg| arg in [:splat, *] }
              case mode
              when :name
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                [literal_name(args[position])].compact
              when :splat
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                args.drop(position).take_while { |arg| !(arg in [:splat, *]) }.filter_map { |arg| literal_name(arg) }
              else
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                return [] unless args[position] in [:array, *elements]
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                elements.filter_map { |arg| literal_name(arg) }
              end
            end

            # @param node [::Parser::AST::Node, nil]
            # @return [String, nil]
            def literal_name node
              return nil unless node in [:sym | :str, Symbol | String => value]
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name = value.to_s
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name.empty? ? nil : name
            end
          end
        end
      end
    end
  end
end
