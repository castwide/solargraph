# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CvasgnNode < Parser::NodeProcessor::Base
          def process
            # s(:cvasgn, name, value) - value is absent when the target is in an mlhs
            node => [:cvasgn, Symbol => name, *rest]
            assignment = (rest in [::Parser::AST::Node => value, *]) ? value : nil

            loc = get_node_location(node)
            pins.push Solargraph::Pin::ClassVariable.new(
              location: loc,
              closure: region.closure,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name: name.to_s,
              comments: comments_for(node),
              type_assertion: type_assertion_for(node),
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
