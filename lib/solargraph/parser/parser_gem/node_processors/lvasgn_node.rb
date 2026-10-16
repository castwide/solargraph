# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class LvasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # s(:lvasgn, name, value) - value is absent in an mlhs or a rescue
            node => [:lvasgn, Symbol => name, *rest]
            assignment = (rest in [::Parser::AST::Node => value, *]) ? value : nil # rubocop:disable Style/RedundantParentheses

            here = get_node_start_position(node)
            # @sg-ignore Need to add nil check here
            presence = Range.new(here, region.closure.location.range.ending)
            loc = get_node_location(node)
            locals.push Solargraph::Pin::LocalVariable.new(
              location: loc,
              closure: region.closure,
              name: name.to_s,
              assignment: assignment,
              comments: comments_for(node),
              presence: presence,
              source: :parser
            )
            process_children
          end
        end
      end
    end
  end
end
