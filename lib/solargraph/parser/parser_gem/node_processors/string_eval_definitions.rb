# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        # Maps methods defined by evaluating a string, e.g.:
        #
        #   %w(edit new).each do |action|
        #     module_eval "def #{action}_url; end"   # => #edit_url, #new_url
        #   end
        #
        #   def define_helper(name)
        #     Helpers.class_eval "def #{name}; end"  # => recorded as a Template
        #   end
        #
        # Interpolations may only read variables of a loop over a literal array,
        # or parameters of the enclosing method. Loop variables are expanded where
        # the string appears; parameters are recorded on the method's pin as a
        # Template, which CallSites expands at each call with literal arguments.
        #
        module StringEvalDefinitions
          autoload :Template,  'solargraph/parser/parser_gem/node_processors/string_eval_definitions/template'
          autoload :CallSites, 'solargraph/parser/parser_gem/node_processors/string_eval_definitions/call_sites'

          # @return [Array<Symbol>]
          METHODS = %i[class_eval module_eval instance_eval].freeze

          # The most sources one template may generate. Rails and the gems of
          # a Rails 8 bundle need at most 30.
          # @return [Integer]
          MAX_EXPANSIONS = 256

          # The most template text, times the number of sources, one template
          # may generate. Rails needs at most about 6 KB.
          # @return [Integer]
          MAX_EXPANSION_BYTES = 262_144 # 256 KiB

          # Maps a string evaluation, or records it on the enclosing method.
          class EvalNode < Parser::NodeProcessor::Base
            # @return [Boolean] continue processing the next processor of the same node.
            def process
              StringEvalDefinitions.process node, region, pins if METHODS.include?(node.children[1])
              true
            end
          end

          class << self
            # Process a call to one of METHODS whose first argument is a string.
            #
            # @param node [::Parser::AST::Node] the send node
            # @param region [Parser::Region]
            # @param pins [Array<Pin::Base>]
            # @return [void]
            def process node, region, pins
              string = node.children[2]
              return unless string.is_a?(AST::Node)
              parts = string_parts(string)
              return if parts.nil?
              receiver = node.children[0]
              return unless receiver.nil? || (receiver.is_a?(AST::Node) && (receiver.type == :self || constant_path?(receiver)))
              target = receiver.is_a?(AST::Node) && receiver.type == :const ? Parser::NodeMethods.unpack_name(receiver) : nil
              scope = node.children[1] == :instance_eval ? :class : :instance
              template = build_template(parts, region, target, scope)
              return if template.nil?
              if template.params.empty?
                expand_now template, string, region, pins
              else
                method_pin = enclosing_method(region)
                method_pin&.call_site_templates&.push template
              end
            end

            # Map the methods and instance variables a string defines.
            #
            # @param code [String]
            # @param filename [String, nil]
            # @param line [Integer] the line where the code appears
            # @param closure [Pin::Namespace] the namespace the code is evaluated on
            # @param scope [Symbol]
            # @return [Array<Pin::Base>]
            def map code, filename, line, closure, scope
              source = Source.load_string(("\n" * line) + code, filename)
              root = source.node
              return [] unless source.parsed? && root.is_a?(AST::Node)
              region = Parser::Region.new(source: source, closure: closure, scope: scope)
              pins, _locals, ivars = Parser::NodeProcessor.process(root, region, [closure])
              pins.drop(1) + ivars
            end

            # Every way of choosing one value for each variable.
            #
            # @param choices [Hash{Symbol => Array<String>}]
            # @return [Array<Hash{Symbol => String}>]
            def combinations choices
              # @type [Array<Hash{Symbol => String}>]
              result = [{}]
              choices.each_pair do |var, list|
                # @sg-ignore need to support destructured args in blocks
                result = result.flat_map { |partial| list.map { |value| partial.merge({ var => value }) } }
              end
              result
            end

            # @param parts [Array<String, Symbol>]
            # @param values [Hash{Symbol => String}]
            # @return [String]
            def substitute parts, values
              parts.map { |part| part.is_a?(Symbol) ? values[part].to_s : part }.join
            end

            private

            # @param template [Template]
            # @param string [::Parser::AST::Node]
            # @param region [Parser::Region]
            # @param pins [Array<Pin::Base>]
            # @return [void]
            def expand_now template, string, region, pins
              target = template.target
              closure = target.nil? ? self_namespace(region) : lexical_namespace(target, region, pins)
              return if closure.nil?
              line = body_line(string)
              template.expand({}).each do |code|
                pins.concat map(code, region.filename, line, closure, template.scope)
              end
            end

            # The text of a string literal, with interpolations reduced to the
            # names of the local variables they read.
            #
            # @param node [::Parser::AST::Node]
            # @return [Array<String, Symbol>, nil] nil if the string interpolates
            #   anything but a local variable
            def string_parts node
              return [node.children[0].to_s] if node.type == :str
              return unless node.type == :dstr
              # @type [Array<String, Symbol>]
              parts = []
              node.children.each do |child|
                return nil unless child.is_a?(AST::Node)
                part = child.type == :dstr ? string_parts(child) : string_part(child)
                return nil if part.nil?
                parts.concat part
              end
              parts
            end

            # @param node [::Parser::AST::Node]
            # @return [Array<String, Symbol>, nil]
            def string_part node
              return [node.children[0].to_s] if node.type == :str
              return unless node.type == :begin && node.children.length == 1
              lvar = node.children[0]
              return unless lvar.is_a?(AST::Node) && lvar.type == :lvar
              name = lvar.children[0]
              return unless name.is_a?(Symbol)
              [name]
            end

            # Find where each interpolated variable gets its values. Every block
            # between the string and its method or namespace must be an `each`
            # loop, which leaves self unchanged.
            #
            # @param parts [Array<String, Symbol>]
            # @param region [Parser::Region]
            # @param target [String, nil]
            # @param scope [Symbol]
            # @return [Template, nil]
            def build_template parts, region, target, scope
              loops = enclosing_loops(region)
              return if loops.nil?
              method_pin = enclosing_method(region)
              decls = method_pin ? method_pin.parameters.to_h { |param| [param.name, param.decl] } : {}
              template = Template.new(parts: parts, params: {}, iterated: [], values: {},
                                      target: target, gates: region.closure.gates, scope: scope)
              vars = parts.select { |part| part.is_a?(Symbol) }.uniq
              # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
              template if vars.all? { |var| bind(template, var, loops[var], decls) }
            end

            # Record where a variable gets its values: a parameter, each element
            # of a parameter, or a literal array.
            #
            # @param template [Template]
            # @param var [Symbol]
            # @param source [::Parser::AST::Node, nil] the receiver of the loop
            #   that defines the variable, if any
            # @param decls [Hash{String => Symbol}] the enclosing method's
            #   parameter declarations
            # @return [Boolean] false if the values are unknown
            def bind template, var, source, decls
              if source.nil?
                return false unless %i[arg optarg kwarg kwoptarg].include?(decls[var.to_s])
                template.params[var] = var.to_s
              elsif source.type == :array
                list = literal_values(source)
                return false if list.nil?
                template.values[var] = list
              else
                param = source.children[0].to_s
                return false unless source.type == :lvar && %i[arg restarg].include?(decls[param])
                template.params[var] = param
                template.iterated.push var
              end
              true
            end

            # The variables of the `each` loops around a region, and the receiver
            # of each loop.
            #
            # @param region [Parser::Region]
            # @return [Hash{Symbol => ::Parser::AST::Node}, nil] nil if any
            #   enclosing block is not an `each` loop
            def enclosing_loops region
              # @type [Hash{Symbol => ::Parser::AST::Node}]
              loops = {}
              closure = region.closure
              while closure.is_a?(Pin::Block)
                node = closure.node
                return unless node.is_a?(AST::Node) && node.type == :block
                call, args = node.children
                return unless each_call?(call) && args.is_a?(AST::Node) && args.children.length == 1
                arg = args.children[0]
                receiver = call.children[0]
                return unless arg.is_a?(AST::Node) && arg.type == :arg && receiver.is_a?(AST::Node)
                var = arg.children[0]
                loops[var] ||= receiver if var.is_a?(Symbol)
                closure = closure.closure
              end
              loops
            end

            # @param call [::Parser::AST::Node, nil]
            # @return [Boolean]
            def each_call? call
              return false if call.nil?
              call.type == :send && call.children[1] == :each && call.children.length == 2
            end

            # True for `Foo::Bar` and `::Foo`, false for `obj.klass::Foo`, whose
            # namespace is not known from the source.
            #
            # @param node [::Parser::AST::Node]
            # @return [Boolean]
            def constant_path? node
              return false unless node.type == :const
              base = node.children[0]
              return true if base.nil?
              return false unless base.is_a?(AST::Node)
              base.type == :cbase || constant_path?(base)
            end

            # @param region [Parser::Region]
            # @return [Pin::Method, nil]
            def enclosing_method region
              closure = region.closure
              closure = closure.closure while closure.is_a?(Pin::Block)
              closure.is_a?(Pin::Method) ? closure : nil
            end

            # @param array [::Parser::AST::Node]
            # @return [Array<String>, nil] nil unless every element is a literal
            def literal_values array
              array.children.map do |child|
                return nil unless child.is_a?(AST::Node) && %i[str sym].include?(child.type)
                child.children[0].to_s
              end
            end

            # The namespace self refers to where a string is evaluated outside a
            # method.
            #
            # @param region [Parser::Region]
            # @return [Pin::Namespace, nil]
            def self_namespace region
              closure = region.closure
              closure = closure.closure while closure.is_a?(Pin::Block)
              return unless closure.instance_of?(Pin::Namespace)
              closure
            end

            # Resolve a constant to a namespace defined earlier in the same file,
            # or take it as written from the top level.
            #
            # @param name [String]
            # @param region [Parser::Region]
            # @param pins [Array<Pin::Base>]
            # @return [Pin::Namespace]
            def lexical_namespace name, region, pins
              candidates = region.closure.gates.map { |gate| gate.empty? ? name : "#{gate}::#{name}" }
              namespaces = pins.grep(Pin::Namespace)
              candidates.each do |path|
                found = namespaces.find { |pin| pin.path == path }
                return found if found
              end
              Pin::Namespace.new(name: name, closure: Pin::ROOT_PIN, source: :parser)
            end

            # @param node [::Parser::AST::Node]
            # @return [Integer]
            def body_line node
              loc = node.location
              # @sg-ignore https://github.com/castwide/solargraph/pull/1259
              return loc.heredoc_body.line if loc.is_a?(::Parser::Source::Map::Heredoc)
              loc.expression.line
            end
          end
        end
      end
    end
  end
end
