# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            # s(:resbody, s(:array, *exception_classes) | nil, s(:lvasgn, name) | nil, body)
            return process_children unless node in [:resbody,
                                                    ::Parser::AST::Node | nil => exceptions,
                                                    ::Parser::AST::Node | nil => variable,
                                                    ::Parser::AST::Node | nil => body]

            # variable is an lvasgn, ivasgn, cvasgn or gvasgn (Symbol name), a
            # send for `=> a.b` (receiver node) or a casgn for `=> A` (nil scope)
            if variable in [_, Symbol | ::Parser::AST::Node | nil => variable_name, *]

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
                name: variable_name.to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence,
                source: :parser
              )
            end
            NodeProcessor.process(body, region, pins, locals, ivars)
          end
        end
      end
    end
  end
end
