# frozen_string_literal: true

require 'parser'

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OpasgnNode < Parser::NodeProcessor::Base
          on_node_pattern_enter '(op_asgn $send $_ $_)', :process_send_target
          on_node_pattern_enter '(op_asgn ${lvasgn ivasgn cvasgn gvasgn} $_ $_)', :process_vasgn_target
          on_node_pattern_enter '(op_asgn $[!send !lvasgn !ivasgn !cvasgn !gvasgn] ...)', :process_unknown_target

          # @param call [RuboCop::AST::SendNode] the target of the assignment
          # @param operator [Symbol] the operator, e.g. :+
          # @param argument [Parser::AST::Node] the argument of the operation
          #
          # @return [void]
          def process_send_target call, operator, argument
            skip_children
            # if target is a call:
            # [10] pry(main)> Parser::CurrentRuby.parse("Foo.bar += baz")
            # => s(:op_asgn,
            #      s(:send, # call
            #        s(:const, nil, :Foo), # calee
            #        :bar), # call_method
            #      :+, # operator
            #      s(:send, nil, :baz)) # argument
            # [11] pry(main)>
            callee = call.receiver
            call_method = call.method_name
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
            walk new_send
          end

          # @param asgn [RuboCop::AST::AsgnNode] the target of the assignment
          # @param operator [Symbol] the operator, e.g. :+
          # @param argument [Parser::AST::Node] the argument of the operation
          #
          # @return [void]
          def process_vasgn_target asgn, operator, argument
            skip_children
            # => s(:op_asgn,
            #      s(:lvasgn, :a), # asgn
            #      :+, # operator
            #      s(:int, 2)) # argument

            variable_name = asgn.name
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
            walk new_asgn
          end

          # @param target [Parser::AST::Node]
          # @return [void]
          def process_unknown_target target
            skip_children
            Solargraph.assert_or_log(:opasgn_unknown_target,
                                     "Unexpected op_asgn target type: #{target.type}")
          end
        end
      end
    end
  end
end
