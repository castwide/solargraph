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
                node.children.each do |child|
                  # s(:args, *params) - every parameter is a node
                  # raises NoMatchingPatternError on a non-node child
                  child => ::Parser::AST::Node => u
                  # s(:arg, name), s(:optarg, name, default), s(:restarg) for an anonymous splat,
                  # or s(:mlhs, *args) for |(a, b)|
                  name = (u in [_, Symbol | ::Parser::AST::Node | nil => first, *]) ? first : nil
                  default = (u in [_, _, ::Parser::AST::Node => second, *]) ? second : nil
                  loc = get_node_location(u)
                  # @sg-ignore https://github.com/castwide/solargraph/pull/1451
                  param = Solargraph::Pin::Parameter.new(
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
                  locals.push param
                  callable.parameters.push param
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
            param = Solargraph::Pin::Parameter.new(
              location: loc,
              closure: callable,
              # @sg-ignore Need to add nil check here
              presence: region.closure.location.range,
              decl: get_decl(node),
              source: :parser
            )
            locals.push param
            callable.parameters.push param
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
