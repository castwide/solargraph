# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class MasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
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
            # @type [Parser::AST::Node]
            mlhs = masgn.children.fetch(0)
            # @type [Array<Parser::AST::Node>]
            lhs_arr = mlhs.children
            # @type [Parser::AST::Node]
            mass_rhs = node.children.fetch(1)

            # Get pins created for the mlhs node
            process_children

            splat_seen = false
            lhs_arr.each_with_index do |lhs, i|
              # Targets after a splat count from the end of the value
              # (`*a, b = x` gives b the last element), so their index
              # is negative
              splat_seen ||= lhs.type == :splat
              # @sg-ignore https://github.com/apiology/solargraph/pull/286
              index = splat_seen ? i - lhs_arr.length : i
              location = get_node_location(lhs)
              pin = if lhs.type == :lvasgn
                      # lvasgn is a local variable
                      locals.find { |l| l.location == location }
                    elsif lhs.type == :ivasgn
                      # ivasgn is an instance variable assignment
                      ivars.find { |iv| iv.location == location }
                    else
                      pins.find { |iv| iv.location == location && iv.is_a?(Pin::BaseVariable) }
                    end
              # @todo in line below, nothing in typechecking alerts
              #   when a non-existant method is called on 'l'
              if pin.nil?
                Solargraph.logger.debug do
                  "Could not find local for masgn= value in location #{location.inspect} in #{lhs_arr} - masgn = #{masgn}, lhs.type = #{lhs.type}"
                end
                next
              end
              pin.mass_assignment = [mass_rhs, index]
            end
          end
        end
      end
    end
  end
end
