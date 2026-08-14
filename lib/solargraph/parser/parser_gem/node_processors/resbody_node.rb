# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            if node.children[1] # Exception local variable name
              here = get_node_start_position(node.children[1])
              # @sg-ignore Need to add nil check here
              presence = Range.new(here, region.closure.location.range.ending)
              loc = get_node_location(node.children[1])
              types = if node.children[0].nil?
                        ['Exception']
                      else
                        node.children[0].children.map do |child|
                          unpack_name(child)
                        end
                      end
              locals.push Solargraph::Pin::LocalVariable.new(
                location: loc,
                closure: region.closure,
                name: node.children[1].children[0].to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence,
                source: :parser
              )
            end
            # not pushed onto `pins` - and/or/orasgn/resbody bodies are
            # too common to warrant a pin per occurrence, so only the
            # pointer is needed for the compound_statement chain
            # @sg-ignore Need to add nil check here
            rescue_body_cs = Solargraph::Pin::CompoundStatement.new(
              # @sg-ignore Need to add nil check here
              location: node.children[2] ? get_node_location(node.children[2]) : nil,
              closure: region.closure,
              compound_statement: region.compound_statement,
              node: node.children[2],
              source: :parser
            )
            # @sg-ignore Need to add nil check here
            NodeProcessor.process(node.children[2], region.update(compound_statement: rescue_body_cs, conditional: true), pins, locals, ivars)
          end
        end
      end
    end
  end
end
