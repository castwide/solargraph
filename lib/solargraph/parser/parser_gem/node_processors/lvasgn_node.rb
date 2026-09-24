# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class LvasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            here = get_node_start_position(node)
            name = node.children[0].to_s
            closure = assignment_closure(name, here)
            # @sg-ignore Need to add nil check here
            presence = Range.new(here, closure.location.range.ending)
            loc = get_node_location(node)
            locals.push Solargraph::Pin::LocalVariable.new(
              location: loc,
              closure: closure,
              name: name,
              assignment: node.children[1],
              comments: comments_for(node),
              presence: presence,
              source: :parser
            )
            process_children
          end

          private

          # The closure `name` is already declared in, searching outward
          # through enclosing blocks; defaults to the current block if none.
          #
          # @param name [String]
          # @param here [Position]
          # @return [Pin::Closure]
          def assignment_closure name, here
            scope = region.closure
            loop do
              return scope if declares_local?(scope, name, here)
              break unless scope.is_a?(Pin::Block)

              outer = scope.closure
              break if outer.nil? || outer.location.nil?

              scope = outer
            end
            region.closure
          end

          # @param scope [Pin::Closure]
          # @param name [String]
          # @param here [Position]
          # @return [Boolean]
          def declares_local? scope, name, here
            locals.any? do |pin|
              pin.name == name && pin.closure.equal?(scope) && pin.presence&.contain?(here)
            end
          end
        end
      end
    end
  end
end
