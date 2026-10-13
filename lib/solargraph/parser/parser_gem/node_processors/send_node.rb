# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SendNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_pattern_enter '(send _ !Symbol ...)', :process_invalid_method_name
          on_node_pattern_enter '(send nil? ${:private :public :protected} $...)', :process_visibility
          on_node_pattern_enter '(send nil? :module_function)', :process_module_function
          on_node_pattern_enter '(send nil? :module_function ({sym str} _) ...)', :process_module_function_names
          on_node_pattern_enter '(send nil? :module_function $def ...)', :process_module_function_def
          on_node_pattern_enter '(send nil? ${:attr_reader :attr_writer :attr_accessor} $...)', :process_attribute
          on_node_pattern_enter '(send nil? :include const ...)', :process_include
          on_node_pattern_enter '(send nil? :extend ...)', :process_extend
          on_node_pattern_enter '(send nil? :prepend const ...)', :process_prepend
          on_node_pattern_enter '(send nil? :require (str $_) ...)', :process_require
          on_node_pattern_enter '(send nil? :autoload _ (str $_) ...)', :process_require
          on_node_pattern_enter '(send nil? :private_constant ({sym str} $_) ...)', :process_private_constant
          on_node_pattern_enter '(send nil? :alias_method (sym $_) (sym $_) ...)', :process_alias_method
          on_node_pattern_enter '(send nil? :private_class_method ({sym str} $_) ...)', :process_private_class_method
          on_node_pattern_enter '(send nil? :private_class_method !({sym str} _) ...)',
                                :process_private_class_method_body
          on_node_pattern_enter '(send (const nil? :Bundler) :require ...)', :process_bundler_require

          # @!method node
          #   @return [RuboCop::AST::SendNode]

          private

          # :nocov:
          # @return [void]
          def process_invalid_method_name
            Solargraph.assert_or_log(:parser_method_name,
                                     "Expected method name to be a Symbol, got #{node.children[1].class} for node #{node.inspect}")
          end
          # :nocov:

          # @param visibility [Symbol]
          # @param arguments [Array<::Parser::AST::Node>]
          # @return [void]
          def process_visibility visibility, arguments
            if arguments.empty?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, visibility)
              return
            end

            arguments.each do |child|
              if %i[sym str].include?(child.type)
                name = child.children[0].to_s
                matches = pins.select { |pin| pin.is_a?(Pin::Method) && pin.name == name && pin.namespace == region.closure.full_context.namespace && pin.context.scope == (region.scope || :instance) }
                matches.each do |pin|
                  # @todo Smelly instance variable access
                  pin.instance_variable_set(:@visibility, visibility)
                end
              else
                process_children region.update(visibility: visibility)
              end
            end
          end

          # @param kind [Symbol]
          # @param attributes [Array<::Parser::AST::Node>]
          # @return [void]
          def process_attribute kind, attributes
            attributes.each do |a|
              loc = get_node_location(node)
              clos = region.closure
              cmnt = comments_for(node)
              if %i[attr_reader attr_accessor].include?(kind)
                pins.push Solargraph::Pin::Method.new(
                  location: loc,
                  closure: clos,
                  name: a.children[0].to_s,
                  comments: cmnt,
                  scope: region.scope || :instance,
                  visibility: region.visibility,
                  attribute: true,
                  source: :parser
                )
              end
              next unless %i[attr_writer attr_accessor].include?(kind)
              method_pin = Solargraph::Pin::Method.new(
                location: loc,
                closure: clos,
                name: "#{a.children[0]}=",
                comments: cmnt,
                scope: region.scope || :instance,
                visibility: region.visibility,
                attribute: true,
                source: :parser
              )
              pins.push method_pin
              method_pin.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pins.last,
                                                            source: :parser)
              if method_pin.return_type.defined?
                pins.last.docstring.add_tag YARD::Tags::Tag.new(:param, '',
                                                                pins.last.return_type.items.map(&:rooted_tags), 'value')
              end
            end
          end

          # @return [void]
          def process_include
            cp = region.closure
            node.arguments.each do |i|
              type = region.scope == :class ? Pin::Reference::Extend : Pin::Reference::Include
              pins.push type.new(
                location: get_node_location(i),
                closure: cp,
                name: unpack_name(i),
                source: :parser
              )
            end
          end

          # @return [void]
          def process_prepend
            cp = region.closure
            node.arguments.each do |i|
              pins.push Pin::Reference::Prepend.new(
                location: get_node_location(i),
                closure: cp,
                name: unpack_name(i),
                source: :parser
              )
            end
          end

          # @return [void]
          def process_extend
            node.arguments.each do |i|
              loc = get_node_location(node)
              if i.type == :self
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: region.closure.full_context.namespace,
                  source: :parser
                )
              else
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: unpack_name(i),
                  source: :parser
                )
              end
            end
          end

          # @param path [String]
          # @return [void]
          def process_require path
            pins.push Pin::Reference::Require.new(get_node_location(node), path.to_s, source: :parser)
          end

          # @return [void]
          def process_module_function
            # @todo Smelly instance variable access
            region.instance_variable_set(:@visibility, :module_function)
          end

          # @return [void]
          def process_module_function_names
            node.arguments.each do |x|
              cn = x.children[0].to_s
              # @type [Pin::Method, nil]
              ref = pins.find { |p| p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == cn }
              next if ref.nil?
              pins.delete ref
              mm = Solargraph::Pin::Method.new(
                location: ref.location,
                closure: ref.closure,
                name: ref.name,
                parameters: ref.parameters,
                comments: ref.comments,
                scope: :class,
                visibility: :public,
                node: ref.node,
                source: :parser
              )
              cm = Solargraph::Pin::Method.new(
                location: ref.location,
                closure: ref.closure,
                name: ref.name,
                parameters: ref.parameters,
                comments: ref.comments,
                scope: :instance,
                visibility: :private,
                node: ref.node,
                source: :parser
              )
              pins.push mm, cm
              ivars.select { |pin| pin.is_a?(Pin::InstanceVariable) && pin.closure.path == ref.path }.each do |ivar|
                ivars.delete ivar
                ivars.push Solargraph::Pin::InstanceVariable.new(
                  location: ivar.location,
                  closure: cm,
                  name: ivar.name,
                  comments: ivar.comments,
                  assignment: ivar.assignment,
                  source: :parser
                )
                ivars.push Solargraph::Pin::InstanceVariable.new(
                  location: ivar.location,
                  closure: mm,
                  name: ivar.name,
                  comments: ivar.comments,
                  assignment: ivar.assignment,
                  source: :parser
                )
              end
            end
          end

          # @param definition [::Parser::AST::Node]
          # @return [void]
          def process_module_function_def definition
            walk definition, region.update(visibility: :module_function)
          end

          # @param name [Symbol, String]
          # @return [void]
          def process_private_constant name
            cn = name.to_s
            ref = pins.select do |p|
              [Solargraph::Pin::Namespace,
               Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn
            end.first
            # HACK: Smelly instance variable access
            ref&.instance_variable_set(:@visibility, :private)
          end

          # @param name [Symbol]
          # @param original [Symbol]
          # @return [void]
          def process_alias_method name, original
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name.to_s,
              original: original.to_s,
              scope: region.scope || :instance,
              source: :parser
            )
          end

          # @param name [Symbol, String]
          # @return [void]
          def process_private_class_method name
            ref = pins.select do |p|
              p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == name.to_s
            end.first
            # HACK: Smelly instance variable access
            ref&.instance_variable_set(:@visibility, :private)
          end

          # @return [void]
          def process_private_class_method_body
            process_children region.update(scope: :class, visibility: :private)
          end

          # @return [void]
          def process_bundler_require
            pins.push Pin::Reference::Require.new(
              Solargraph::Location.new(region.filename,
                                       Solargraph::Range.from_to(0, 0, 0, 0)), 'bundler/require', source: :parser
            )
          end
        end
      end
    end
  end
end
