# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class MasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # Example:
            #
            # s(:masgn,
            #   s(:mlhs,
            #     s(:send,
            #       s(:send, nil, :a), :b=),
            #     s(:lvasgn, :b),
            #     s(:ivasgn, :@c)),
            #   s(:array,
            #     s(:int, 1),
            #     s(:int, 2),
            #     s(:int, 3)))
            masgn = node
            mlhs = masgn.children.fetch(0)
            lhs_arr = mlhs.children
            mass_rhs = node.children.fetch(1)

            # Get pins created for the mlhs node
            process_children

            lhs_arr.each_with_index do |lhs, i|
              location = get_node_location(lhs)
              pin = if lhs.type == :lvasgn
                      # lvasgn is a local variable
                      locals.find { |l| l.location == location }
                    else
                      # e.g., ivasgn is an instance variable, etc
                      pins.find { |iv| iv.location == location && iv.is_a?(Pin::BaseVariable) }
                    end
              # @todo in line below, nothing in typechecking alerts
              #   when a non-existant method is called on 'l'
              if pin.nil?
                Solargraph.logger.debug { "Could not find local for masgn= value in location #{location.inspect} in #{lhs_arr} - masgn = #{masgn}, lhs.type = #{lhs.type}" }
                next
              end
              pin.mass_assignment = [mass_rhs, i]
            end
          end
        end
      end
    end
  end
end
