# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      # Converts a YARD `ConstantObject` whose value is an anonymous class
      # definition into the pins that definition would have produced if it had
      # been written as a `class` statement.
      #
      # YARD has no handler for `Class.new`, so `Foo = Class.new(Bar) do ... end`
      # arrives as a constant whose block body survives only as the raw source
      # string in `ConstantObject#value`. That source is reparsed here, wrapped
      # in the constant's original module nesting (so a relative superclass name
      # resolves through the same gates it did in the gem), and mapped with
      # Solargraph's own parser, where `Convention::ClassDefinition` turns it
      # into a namespace, a superclass reference, and method pins.
      module ToClassDefinition
        extend YardMap::Helpers

        autoload :NodeStripper, 'solargraph/yard_map/mapper/to_class_definition/node_stripper'

        # Pin types worth keeping from the reparse. Local variables, blocks and
        # instance variables only carry meaning together with their parser
        # nodes, which are stripped below.
        KEPT_PIN_CLASSES = [Pin::Namespace, Pin::Reference, Pin::Method, Pin::Constant].freeze

        class << self
          # @param code_object [YARD::CodeObjects::ConstantObject]
          # @param spec [Gem::Specification, nil]
          # @return [Array<Pin::Base>, nil] nil when the constant is not an
          #   anonymous class definition, or could not be reparsed
          def make code_object, spec = nil
            value = code_object.value.to_s
            # Cheap rejection before parsing: a matching node always spells the
            # `Class` constant out in the source.
            return nil unless value.include?('Class')

            assignment = "#{code_object.name} = #{value}"
            node = Source.load_string(assignment).node
            return nil if node.nil?
            return nil unless Convention::ClassDefinition::ClassAssignmentNode.match?(node)

            location = object_location(code_object, spec)
            source = Source.load_string(nested_source(namespace_names(code_object), assignment), location.filename)
            definition_pins(source, code_object, location)
          rescue StandardError => e
            Solargraph.logger.info "Could not reparse #{code_object.path} as a class definition: [#{e.class}] #{e.message}"
            nil
          end

          private

          # @param code_object [YARD::CodeObjects::ConstantObject]
          # @return [Array<String>]
          def namespace_names code_object
            code_object.namespace.to_s.split('::').reject(&:empty?)
          end

          # @param namespaces [Array<String>]
          # @param assignment [String]
          # @return [String]
          def nested_source namespaces, assignment
            [
              *namespaces.map { |ns| "module #{ns}" },
              assignment,
              *namespaces.map { 'end' }
            ].join("\n")
          end

          # @param source [Source]
          # @param code_object [YARD::CodeObjects::ConstantObject]
          # @param location [Location]
          # @return [Array<Pin::Base>, nil]
          def definition_pins source, code_object, location
            stripper = NodeStripper.new(location)
            pins = SourceMap.map(source).pins
                            .select { |pin| keep?(pin, code_object) }
                            .map { |pin| stripper.strip(pin) }
            namespace_pin = pins.find { |pin| pin.is_a?(Pin::Namespace) && pin.path == code_object.path }
            return nil if namespace_pin.nil?

            # The constant's own documentation belongs to the class it defines.
            namespace_pin.instance_variable_set(:@comments, code_object.docstring.all.to_s) if code_object.docstring
            pins
          end

          # @param pin [Pin::Base]
          # @param code_object [YARD::CodeObjects::ConstantObject]
          # @return [Boolean]
          def keep? pin, code_object
            return false unless KEPT_PIN_CLASSES.any? { |klass| pin.is_a?(klass) }

            path = pin.path.to_s
            return true if path == code_object.path
            return true if path.start_with?("#{code_object.path}#", "#{code_object.path}.", "#{code_object.path}::")

            # References (superclass, include, extend) have no path of their own.
            path.empty? && descends_from?(pin, code_object.path)
          end

          # @param pin [Pin::Base]
          # @param path [String]
          # @return [Boolean]
          def descends_from? pin, path
            closure = pin.closure
            while closure
              return true if closure.path == path

              closure = closure.closure
            end
            false
          end
        end
      end
    end
  end
end
