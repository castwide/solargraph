# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            conditional_node = node.children[0]
            then_clause = node.children[1]

            process_children

            #
            # See if we can refine a type based on the result of 'if foo.nil?'
            #
            # [3] pry(main)> require 'parser/current'; Parser::CurrentRuby.parse("if foo.is_a? Baz; then foo; else bar; end")
            # => s(:if,
            #   s(:send,
            #     s(:send, nil, :foo), :is_a?,
            #     s(:const, nil, :Baz)),
            #   s(:send, nil, :foo),
            #   s(:send, nil, :bar))
            # [4] pry(main)>
            return unless conditional_node.type == :send && conditional_node.children[1] == :is_a?
            # Check if conditional node follows this pattern:
            #   s(:send,
            #     s(:send, nil, :foo), :is_a?,
            #     s(:const, nil, :Baz)),
            isa_receiver = conditional_node.children[0]
            isa_class = conditional_node.children[2]
            return unless isa_class.type == :const
            # pay attention to above parse tree while writing code
            isa_module = isa_class.children[0]
            if isa_module.nil?
              isa_type_name = isa_class.children[1].to_s
            else
              return unless isa_module.type == :const
              # just handle common cases for now; next step is to
              # recursively add namespaces at the front
              return unless isa_module.children[0].nil?
              isa_type_name = "#{isa_module.children[1]}::#{isa_class.children[1]}"
            end
            # check if isa_receiver looks like this:
            #  s(:send, nil, :foo)
            # and set variable_name to :foo
            if isa_receiver.type == :send && isa_receiver.children[0].nil? && isa_receiver.children[1].is_a?(Symbol)
              variable_name = isa_receiver.children[1].to_s
            end
            # or like this:
            # (lvar :repr)
            variable_name = isa_receiver.children[0].to_s if isa_receiver.type == :lvar
            return if variable_name.nil? || variable_name.empty?

            pins = locals.select { |pin| pin.name == variable_name }
            return unless pins.length == 1

            return if then_clause.nil?

            then_presence = Range.new(get_node_end_position(conditional_node),
                                      get_node_end_position(then_clause))
            # else_presence = Range.new(get_node_start_position(else_clause), get_node_end_position(else_clause))
            pin = pins.first
            # @todo Create pin#update method
            then_pin = Solargraph::Pin::LocalVariable.new(
              location: pin.location,
              closure: pin.closure,
              name: pin.name,
              assignment: pin.assignment,
              comments: pin.comments,
              presence: then_presence,
              return_type: ComplexType.try_parse(isa_type_name)
            )
            locals.push(then_pin)
          end
        end
      end
    end
  end
end
