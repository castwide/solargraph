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

            lhs_arr.each_with_index do |lhs, i|
              # A splat entry (e.g. `*args`) wraps the actual
              # assignment target - `s(:splat, s(:lvasgn, :args))` -
              # and the splat node's own location (which includes
              # the leading `*`) never matches the location of the
              # pin created for the inner assignment target. Unwrap
              # it so the pin lookup below finds the right pin, and
              # remember that this entry captures the "rest" of the
              # right-hand side as an array rather than a single
              # element.
              splat = lhs.type == :splat
              target = splat ? lhs.children[0] : lhs
              # An anonymous splat (`a, * = arr`) has no assignment
              # target to bind a type to.
              next if target.nil?

              location = get_node_location(target)
              pin = if target.type == :lvasgn
                      # lvasgn is a local variable
                      locals.find { |l| l.location == location }
                    elsif target.type == :ivasgn
                      # ivasgn is an instance variable assignment
                      ivars.find { |iv| iv.location == location }
                    else
                      pins.find { |iv| iv.location == location && iv.is_a?(Pin::BaseVariable) }
                    end
              # @todo in line below, nothing in typechecking alerts
              #   when a non-existant method is called on 'l'
              if pin.nil?
                Solargraph.logger.debug do
                  "Could not find local for masgn= value in location #{location.inspect} in #{lhs_arr} - masgn = #{masgn}, target.type = #{target.type}"
                end
                next
              end
              pin.mass_assignment = [mass_rhs, i, splat]
            end
          end
        end
      end
    end
  end
end
