# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ArgsNode < Parser::NodeProcessor::Base
          def process
            callable = region.closure
            if callable.is_a? Pin::Callable
              if node.type == :forward_args
                forward(callable)
              else
                node.children.each do |u|
                  loc = get_node_location(u)
                  locals.push Solargraph::Pin::Parameter.new(
                                location: loc,
                                closure: callable,
                                comments: comments_for(node),
                                name: u.children[0].to_s,
                                assignment: u.children[1],
                                asgn_code: u.children[1] ? region.code_for(u.children[1]) : nil,
                                presence: callable.location.range,
                                decl: get_decl(u)
                              )
                  callable.parameters.push locals.last
                end
              end
            end
            process_children
          end

          private

          # @param callable [Pin::Callable]
          # @return [void]
          def forward(callable)
            loc = get_node_location(node)
            locals.push Solargraph::Pin::Parameter.new(
              location: loc,
              closure: callable,
              presence: region.closure.location.range,
              decl: get_decl(node)
            )
            callable.parameters.push locals.last
          end

          # @param node [AST::Node]
          # @return [Symbol]
          def get_decl node
            node.type
          end
        end
      end
    end
  end
end
