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
            # Not pushed onto `pins`: this CompoundStatement is never
            # looked up on its own (an and/or/orasgn/resbody body has
            # no identity worth indexing the way a def/class does),
            # it only needs to exist as the value every pin created
            # below it (via region.update(compound_statement: ...))
            # carries in its own `compound_statement` field, so those
            # pins can walk back up to find their enclosing
            # conditionally-executed scope. Once processing the body
            # returns, rescue_body_cs itself is discarded.
            # @sg-ignore RBS Array[self] indexing infers Array instead of self
            rescue_body_cs = Solargraph::Pin::CompoundStatement.new(
              # @sg-ignore RBS Array[self] indexing infers Array instead of self
              location: node.children[2] ? get_node_location(node.children[2]) : nil,
              closure: region.closure,
              compound_statement: region.compound_statement,
              conditional: true,
              node: node.children[2],
              source: :parser
            )
            # @sg-ignore RBS Array[self] indexing infers Array instead of self
            NodeProcessor.process(node.children[2], region.update(compound_statement: rescue_body_cs), pins, locals, ivars)
          end
        end
      end
    end
  end
end
