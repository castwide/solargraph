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
                  # s(:arg, name), s(:optarg, name, default), s(:restarg) for an anonymous splat,
                  # or s(:mlhs, *args) for |(a, b)|
                  name = (u in [_, Symbol | ::Parser::AST::Node | nil => first, *]) ? first : nil # rubocop:disable Style/RedundantParentheses
                  default = (u in [_, _, ::Parser::AST::Node => second, *]) ? second : nil # rubocop:disable Style/RedundantParentheses
                  loc = get_node_location(u)
                  locals.push Solargraph::Pin::Parameter.new(
                    location: loc,
                    closure: callable,
                    comments: comments_for(node),
                    name: name.to_s,
                    assignment: default,
                    asgn_code: default ? region.code_for(default) : nil,
                    # @sg-ignore Need to add nil check here
                    presence: callable.location.range,
                    decl: get_decl(u),
                    source: :parser
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
          def forward callable
            loc = get_node_location(node)
            locals.push Solargraph::Pin::Parameter.new(
              location: loc,
              closure: callable,
              # @sg-ignore Need to add nil check here
              presence: region.closure.location.range,
              decl: get_decl(node),
              source: :parser
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
