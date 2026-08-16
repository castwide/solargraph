# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      module ToClassDefinition
        # Copies pins produced by reparsing a gem's source, dropping the parser
        # nodes they hold and pointing them at a location in the gem itself.
        #
        # Nodes have to go for two reasons. They keep a reference to the
        # `Parser::Source::Buffer` they were parsed from, so marshalling the
        # pins into the gem cache marshals the synthesized source with them;
        # and any inference that walks back to a node calls `ApiMap#clip_at`,
        # which raises `FileNotFoundError` unless the node's file has a
        # cataloged source map -- which a gem's source never does.
        #
        # The cost is that these pins cannot infer a return type from a method
        # body. They still carry whatever YARD tags the gem wrote, which is the
        # only typing YARD-sourced pins have anyway.
        class NodeStripper
          # Instance variables that hold parser nodes, by the pin types that
          # define them: methods and blocks (`@node`), blocks (`@receiver`) and
          # variables (`@assignments`, `@mass_assignment`).
          NODE_IVARS = %i[@node @receiver @assignments @mass_assignment].freeze

          # @param location [Location] the location to give every copied pin
          # @param source [::Symbol] the provenance to record on every copied pin
          def initialize location, source: :yardoc
            @location = location
            @source = source
            # @type [Hash{Pin::Base => Pin::Base}]
            @stripped = {}.compare_by_identity
          end

          # @param pin [Pin::Base, nil]
          # @return [Pin::Base, nil]
          def strip pin
            return pin if pin.nil? || pin.equal?(Pin::ROOT_PIN)
            return @stripped[pin] if @stripped.key?(pin)

            copy = pin.dup
            @stripped[pin] = copy
            relocate copy
            clear_nodes copy
            rewire copy
            copy
          end

          private

          # @return [Location]
          attr_reader :location

          # @return [::Symbol]
          attr_reader :source

          # The reparsed source does not exist on disk, so every pin points at
          # the constant that produced it instead.
          #
          # @param pin [Pin::Base]
          # @return [void]
          def relocate pin
            pin.instance_variable_set(:@location, location)
            pin.instance_variable_set(:@type_location, location) unless pin.type_location.nil?
            pin.instance_variable_set(:@source, source)
          end

          # @param pin [Pin::Base]
          # @return [void]
          def clear_nodes pin
            NODE_IVARS.each do |name|
              next unless pin.instance_variable_defined?(name)

              empty = pin.instance_variable_get(name).is_a?(::Array) ? [].freeze : nil
              pin.instance_variable_set(name, empty)
            end
            # A memoized YARD::Docstring links back to the code object it was
            # parsed against, and marshalling one drags the entire YARD
            # registry along with it. Pins regenerate it from #comments.
            pin.instance_variable_set(:@docstring, nil)
          end

          # Pins reference each other -- a method's parameters point back at the
          # method -- so every reachable pin has to be replaced with its copy,
          # or a stripped pin still holds a node through its neighbor.
          #
          # @param pin [Pin::Base]
          # @return [void]
          def rewire pin
            pin.instance_variable_set(:@closure, strip(pin.closure)) unless pin.closure.nil?
            strip_pin_ivar pin, :@block
            strip_pin_list pin, :@parameters
            strip_pin_list pin, :@signatures
          end

          # @param pin [Pin::Base]
          # @param name [Symbol]
          # @return [void]
          def strip_pin_ivar pin, name
            value = pin.instance_variable_get(name) if pin.instance_variable_defined?(name)
            pin.instance_variable_set(name, strip(value)) if value.is_a?(Pin::Base)
          end

          # @param pin [Pin::Base]
          # @param name [Symbol]
          # @return [void]
          def strip_pin_list pin, name
            value = pin.instance_variable_get(name) if pin.instance_variable_defined?(name)
            return unless value.is_a?(::Array)

            pin.instance_variable_set(name, strip_all(value))
          end

          # @param pins [::Array<Pin::Base>]
          # @return [::Array<Pin::Base, nil>]
          def strip_all pins
            pins.map { |item| strip(item) }
          end
        end
      end
    end
  end
end
