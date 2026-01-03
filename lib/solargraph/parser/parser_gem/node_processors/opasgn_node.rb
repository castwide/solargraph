# frozen_string_literal: true

require 'parser'

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OpasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            target = node.children[0]
            operator = node.children[1]
            argument = node.children[2]
            if target.type == :send
              # @sg-ignore Need a downcast here
              process_send_target(target, operator, argument)
            elsif target.type.to_s.end_with?('vasgn')
              # @sg-ignore Need a downcast here
              process_vasgn_target(target, operator, argument)
            else
              Solargraph.assert_or_log(:opasgn_unknown_target,
                                       "Unexpected op_asgn target type: #{target.type}")
            end
          end

          # @param call [Parser::AST::Node] the target of the assignment
          # @param operator [Symbol] the operator, e.g. :+
          # @param argument [Parser::AST::Node] the argument of the operation
          #
          # @return [void]
          def process_send_target call, operator, argument
            # if target is a call:
            # [10] pry(main)> Parser::CurrentRuby.parse("Foo.bar += baz")
            # => s(:op_asgn,
            #      s(:send, # call
            #        s(:const, nil, :Foo), # calee
            #        :bar), # call_method
            #      :+, # operator
            #      s(:send, nil, :baz)) # argument
            # [11] pry(main)>
            callee = call.children[0]
            call_method = call.children[1]
            asgn_method = :"#{call_method}="

            # [8] pry(main)> Parser::CurrentRuby.parse("Foo.bar = Foo.bar + baz")
            # => s(:send,
            #       s(:const, nil, :Foo), # callee
            #       :bar=, # asgn_method
            #        s(:send,
            #          s(:send,
            #             s(:const, nil, :Foo), # callee
            #             :bar), # call_method
            #          :+, # operator
            #          s(:send, nil, :baz))) # argument
            new_send = node.updated(:send,
                                    [callee,
                                     asgn_method,
                                     node.updated(:send, [call, operator, argument])])
            NodeProcessor.process(new_send, region, pins, locals)
          end

          # @param asgn [Parser::AST::Node] the target of the assignment
          # @param operator [Symbol] the operator, e.g. :+
          # @param argument [Parser::AST::Node] the argument of the operation
          #
          # @return [void]
          def process_vasgn_target asgn, operator, argument
            # => s(:op_asgn,
            #      s(:lvasgn, :a), # asgn
            #      :+, # operator
            #      s(:int, 2)) # argument

            # @type [Parser::AST::Node]
            variable_name = asgn.children[0]
            # for lvasgn, gvasgn, cvasgn, convert to lvar, gvar, cvar
            # [6] pry(main)> Parser::CurrentRuby.parse("a = a + 1")
            # => s(:lvasgn, :a,
            #   s(:send,
            #     s(:lvar, :a), :+,
            #     s(:int, 1)))
            # [7] pry(main)>
            variable_reference_type = asgn.type.to_s.sub(/vasgn$/, 'var').to_sym
            target_reference = node.updated(variable_reference_type, asgn.children)
            send_children = [
              target_reference,
              operator,
              argument
            ]
            send_node = node.updated(:send, send_children)
            new_asgn = node.updated(asgn.type, [variable_name, send_node])
            NodeProcessor.process(new_asgn, region, pins, locals)
          end
        end
      end
    end
  end
end
