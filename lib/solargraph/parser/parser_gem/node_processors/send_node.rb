# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SendNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @sg-ignore @override is adding, not overriding
          def process
            # s(:send, receiver, method_name, *args)
            # @sg-ignore Variable type could not be inferred for method_name
            return process_children unless node in [:send, receiver, method_name, *args]

            # :nocov:
            unless method_name.instance_of?(Symbol)
              Solargraph.assert_or_log(:parser_method_name,
                                       "Expected method name to be a Symbol, got #{method_name.class} for node #{node.inspect}")
              return process_children
            end
            # :nocov:
            if receiver.nil?
              if %i[private public protected].include?(method_name)
                process_visibility
              elsif method_name == :module_function
                process_module_function
              elsif %i[attr_reader attr_writer attr_accessor].include?(method_name)
                process_attribute
              elsif method_name == :include
                process_include
              elsif method_name == :extend
                process_extend
              elsif method_name == :prepend
                process_prepend
              elsif method_name == :require
                process_require
              elsif method_name == :autoload
                process_autoload
              elsif method_name == :private_constant
                process_private_constant
              elsif method_name == :alias_method && (args in [[:sym, *], [:sym, *], *])
                process_alias_method
              elsif method_name == :private_class_method && (args in [::AST::Node, *])
                # Processing a private class can potentially handle children on its own
                return if process_private_class_method
              end
            elsif method_name == :require && (receiver in [:const, nil, :Bundler])
              pins.push Pin::Reference::Require.new(
                Solargraph::Location.new(region.filename,
                                         Solargraph::Range.from_to(0, 0, 0, 0)), 'bundler/require', source: :parser
              )
            end
            process_children
          end

          private

          # @return [void]
          def process_visibility
            # @sg-ignore Variable type could not be inferred for method_name
            return unless node in [:send, _, visibility, *args]

            if args.empty?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, visibility)
            else
              # @sg-ignore Need to add nil check here
              args.each do |child|
                # :nocov:
                unless visibility.instance_of?(Symbol)
                  Solargraph.assert_or_log(:parser_visibility,
                                           "Expected visibility name to be a Symbol, got #{visibility.class} for node #{node.inspect}")
                  return process_children
                end
                # :nocov:
                if child in ::Parser::AST::Node[:sym | :str, value, *]
                  name = value.to_s
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
          end

          # @return [void]
          def process_attribute
            return unless node in [:send, _, attr_method, *args]

            # @sg-ignore Need to add nil check here
            args.each do |a|
              # s(:sym, name) or s(:str, name); attr_reader(*X) passes s(:splat, s(:const, nil, :X))
              attr_name = (a in [_, value, *]) ? value : nil # rubocop:disable Style/RedundantParentheses
              loc = get_node_location(node)
              clos = region.closure
              cmnt = comments_for(node)
              if %i[attr_reader attr_accessor].include?(attr_method)
                pins.push Solargraph::Pin::Method.new(
                  location: loc,
                  closure: clos,
                  name: attr_name.to_s,
                  comments: cmnt,
                  scope: region.scope || :instance,
                  visibility: region.visibility,
                  attribute: true,
                  source: :parser
                )
              end
              next unless %i[attr_writer attr_accessor].include?(attr_method)
              method_pin = Solargraph::Pin::Method.new(
                location: loc,
                closure: clos,
                name: "#{attr_name}=",
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
            return unless node in [:send, _, _, *args]
            return unless args in [::AST::Node[:const, *], *]

            cp = region.closure
            # @sg-ignore Need to add nil check here
            args.each do |i|
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
            return unless node in [:send, _, _, *args]
            return unless args in [::AST::Node[:const, *], *]

            cp = region.closure
            # @sg-ignore Need to add nil check here
            args.each do |i|
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
            return unless node in [:send, _, _, *args]

            # @sg-ignore Need to add nil check here
            args.each do |i|
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

          # @return [void]
          def process_require
            # require 'path' - s(:send, nil, :require, s(:str, path))
            return unless node in [:send, _, _, ::AST::Node[:str, value, *], *]

            path = value.to_s
            pins.push Pin::Reference::Require.new(get_node_location(node), path, source: :parser)
          end

          # @return [void]
          def process_autoload
            # autoload :Name, 'path' - s(:send, nil, :autoload, s(:sym, name), s(:str, path))
            return unless node in [:send, _, _, _, ::AST::Node[:str, value, *], *]

            path = value.to_s
            pins.push Pin::Reference::Require.new(get_node_location(node), path, source: :parser)
          end

          # @return [void]
          def process_module_function
            return unless node in [:send, _, _, *args]

            if args.empty?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, :module_function)
            elsif args in [[:sym | :str, *], *]
              # @sg-ignore Need to add nil check here
              args.each do |x|
                cn = (x in [_, value, *]) ? value.to_s : '' # rubocop:disable Style/RedundantParentheses
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
            elsif args in [[:def, *] => def_node, *]
              NodeProcessor.process def_node, region.update(visibility: :module_function), pins, locals, ivars
            end
          end

          # @return [void]
          def process_private_constant
            return unless node in [:send, _, _, [:sym | :str, value, *], *]

            cn = value.to_s
            ref = pins.select do |p|
              [Solargraph::Pin::Namespace,
               Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn
            end.first
            # HACK: Smelly instance variable access
            ref&.instance_variable_set(:@visibility, :private)
          end

          # @return [void]
          def process_alias_method
            # alias_method :new, :old - s(:send, nil, :alias_method, s(:sym, new), s(:sym, old))
            return unless node in [:send, _, _, [_, new_name, *], [_, original, *], *]

            get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: region.closure,
              name: new_name.to_s,
              original: original.to_s,
              scope: region.scope || :instance,
              source: :parser
            )
          end

          # @return [Boolean]
          def process_private_class_method
            if node in [:send, _, _, [:sym | :str, value, *], *]
              ref = pins.select do |p|
                p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == value.to_s
              end.first
              # HACK: Smelly instance variable access
              ref&.instance_variable_set(:@visibility, :private)
              false
            else
              process_children region.update(scope: :class, visibility: :private)
              true
            end
          end
        end
      end
    end
  end
end
