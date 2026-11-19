# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # s(:casgn, scope, name, value) - scope is nil for a bare name; value is absent in an mlhs
            node => [:casgn, ::Parser::AST::Node | nil => scope, Symbol => name, *rest]
            assignment = (rest in [::Parser::AST::Node => value, *]) ? value : nil

            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: const_name(scope, name),
              comments: comments_for(node),
              assignment: assignment,
              source: :parser
            )
            process_children
          end

          private

          # @param scope [Parser::AST::Node, nil]
          # @param name [Symbol]
          # @return [String]
          def const_name scope, name
            if scope
              Parser::NodeMethods.unpack_name(scope) + "::#{name}"
            else
              name.to_s
            end
          end
        end
      end
    end
  end
end
