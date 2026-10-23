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
            scrub_ivars copy
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

          # Every instance variable is examined by the type of what it holds
          # rather than by name, because naming the ivars to clear only works
          # until a pin grows another one -- `Pin::Method#compound_statement`
          # arrived after this class was written and slipped straight through a
          # name-based list.
          #
          # Pins reference each other (a method's parameters point back at the
          # method, a pin's closure chain runs through its compound statements),
          # so every reachable pin is replaced by its copy; leaving one in place
          # would keep a node alive through a neighbor.
          #
          # @param pin [Pin::Base]
          # @return [void]
          def scrub_ivars pin
            pin.instance_variables.each do |name|
              value = pin.instance_variable_get(name)
              scrubbed = scrub(name, value)
              pin.instance_variable_set(name, scrubbed) unless scrubbed.equal?(value)
            end
            # A memoized YARD::Docstring links back to the code object it was
            # parsed against, and marshalling one drags the entire YARD registry
            # along with it. Pins regenerate it from #comments.
            pin.instance_variable_set(:@docstring, nil)
          end

          # @param name [::Symbol]
          # @param value [Object]
          # @return [Object]
          def scrub name, value
            case value
            when ::Parser::AST::Node, ::YARD::Docstring then nil
            when Pin::Base then strip(value)
            when ::Array then scrub_array(name, value)
            else value
            end
          end

          # @param name [::Symbol]
          # @param value [::Array<::Object>]
          # @return [Object]
          def scrub_array name, value
            return value.map { |item| item.is_a?(Pin::Base) ? strip(item) : item } if value.any?(Pin::Base)
            return value unless value.any?(::Parser::AST::Node)

            # `@mass_assignment` is a (node, index) pair rather than a list of
            # nodes, so emptying it would leave a malformed pair behind.
            name == :@mass_assignment ? nil : [].freeze
          end
        end
      end
    end
  end
end
