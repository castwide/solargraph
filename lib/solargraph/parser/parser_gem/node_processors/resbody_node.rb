# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_pattern_enter '(resbody $_ $_ $_)', :process

          # @param exceptions [Parser::AST::Node, nil]
          # @param variable [Parser::AST::Node, nil]
          # @param body [Parser::AST::Node, nil]
          # @return [void]
          def process exceptions, variable, body
            skip_children
            if variable
              here = get_node_start_position(variable)
              # @sg-ignore Need to add nil check here
              presence = Range.new(here, region.closure.location.range.ending)
              loc = get_node_location(variable)
              types = if exceptions.nil?
                        ['Exception']
                      else
                        exceptions.children.map do |child|
                          unpack_name(child)
                        end
                      end
              locals.push Solargraph::Pin::LocalVariable.new(
                location: loc,
                closure: region.closure,
                name: variable.children[0].to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence,
                source: :parser
              )
            end
            walk body
          end
        end
      end
    end
  end
end
