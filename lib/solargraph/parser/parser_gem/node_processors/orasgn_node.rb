# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          on_node_pattern_enter '(or_asgn $_ $_)', :process

          # @param asgn [::Parser::AST::Node]
          # @param value [::Parser::AST::Node]
          # @return [void]
          def process asgn, value
            skip_children
            walk node.updated(asgn.type, asgn.children + [value])
          end
        end
      end
    end
  end
end
