# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        # @param word [String]
        # @param node [Parser::AST::Node, nil] The node representing the variable
        # @param location [Location, nil] The location of the variable reference in the source
        def initialize word, node, location
          super(word)
          @node = node
          @location = location
        end

        def resolve api_map, name_pin, locals
          ivars = api_map.get_instance_variable_pins(name_pin.context.namespace, name_pin.context.scope).select do |p|
            p.name == word
          end
          api_map.var_pins_at_location(reaching(ivars, name_pin), word, name_pin, location)
        end

        private

        # @return [Location, nil]
        attr_reader :location

        # When an assignment dominates this read, the read sees that
        # assignment, combined with the pins starting between it and
        # the read - later conditional assignments and narrowings -
        # rather than every assignment of the ivar.
        #
        # @param ivars [::Array<Pin::InstanceVariable>]
        # @param closure [Pin::Closure]
        # @return [::Array<Pin::InstanceVariable>]
        def reaching ivars, closure
          here = location
          return ivars unless here

          # `@x = value` evaluates to value, which its own pin types
          own = ivars.find { |pin| pin.presence.nil? && pin.location == here } if assignment_with_value?
          return [own] if own

          dominating = ivars.select { |pin| pin.dominates?(closure, here) }
          # @sg-ignore flow sensitive typing needs to handle attrs
          latest = dominating.max_by { |pin| pin.location.range.start }
          return ivars unless latest

          # @sg-ignore flow sensitive typing needs to handle attrs
          after = latest.location.range.start
          between = ivars.select do |pin|
            start = pin.presence&.start || pin.location&.range&.start
            pin.location&.filename == here.filename && start &&
              (start <=> after) == 1 && (start <=> here.range.start) == -1
          end
          [latest] + between
        end

        # True for `@x = value`; false for a read, or for the bare
        # target of `@x ||= value`, which names the previous value
        #
        # @return [Boolean]
        def assignment_with_value?
          node = @node
          return false unless node

          node.type == :ivasgn && node.children.length == 2
        end
      end
    end
  end
end
