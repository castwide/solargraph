# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            # s(:or_asgn, s(:lvasgn, name), value) is processed as s(:lvasgn, name, value)
            return process_children unless node in [:or_asgn,
                                                    ::Parser::AST::Node[Symbol => target_type, *target_children],
                                                    ::Parser::AST::Node => value]

            new_node = node.updated(target_type, target_children + [value])
            NodeProcessor.process(new_node, region, pins, locals, ivars)
          end
        end
      end
    end
  end
end
