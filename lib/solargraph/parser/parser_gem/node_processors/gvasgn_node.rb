# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class GvasgnNode < Parser::NodeProcessor::Base
          def process
            # s(:gvasgn, name, value) - value is absent when the target is in an mlhs
            node => [:gvasgn, Symbol => name, *rest]
            assignment = (rest in [::Parser::AST::Node => value, *]) ? value : nil

            loc = get_node_location(node)
            pins.push Solargraph::Pin::GlobalVariable.new(
              location: loc,
              closure: region.closure,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name: name.to_s,
              comments: comments_for(node),
              assignment: assignment,
              source: :parser
            )
            process_children
          end
        end
      end
    end
  end
end
