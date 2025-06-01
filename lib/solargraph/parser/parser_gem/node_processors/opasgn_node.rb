# frozen_string_literal: true

require 'parser'

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OpasgnNode < Parser::NodeProcessor::Base
          def process
            # Parser::CurrentRuby.parse("a += 2")
            # => s(:op_asgn,
            #      s(:lvasgn, :a), :+,
            #      s(:int, 2))
            asgn = node.children[0]
            variable_name = asgn.children[0]
            operator = node.children[1]
            argument = node.children[2]
            # for lvasgn, gvasgn, cvasgn, convert to lvar, gvar, cvar
            # [6] pry(main)> Parser::CurrentRuby.parse("a = a + 1")
            # => s(:lvasgn, :a,
            #   s(:send,
            #     s(:lvar, :a), :+,
            #     s(:int, 1)))
            # [7] pry(main)>
            variable_reference_type = asgn.type.to_s.sub(/vasgn$/, 'var').to_sym
            variable_reference = node.updated(variable_reference_type, asgn.children)
            send_children = [
              variable_reference,
              operator,
              argument
            ]
            send_node = node.updated(:send, send_children)
            new_asgn = node.updated(asgn.type, [variable_name,  send_node])
            NodeProcessor.process(new_asgn, region, pins, locals)
          end
        end
      end
    end
  end
end
