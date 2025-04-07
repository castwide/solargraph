module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # @param locals [Array<Solargraph::Pin::BaseVariable>]
      def initialize(locals, enclosing_block_pin = nil)
        @locals = locals
        @enclosing_block_pin = enclosing_block_pin
      end

      # @param node [Parser::AST::Node]
      # @return [void]
      def run(node)
        process_node(node)
      end

      def process_node(node)
        return process_if(node) if node.type == :if
        # process_or(node) if node.type == :or
      end

      # def process_or(node)
      #   lhs = node.children[0]
      #   rhs = node.children[1]
      #   if_true = {}
      #   if_false = {}
      #   gather_facts(conditional_node, if_true, if_false)
      # end

      # @param node [Parser::AST::Node]
      def type_name(node)
        # e.g.,
        #  s(:const, nil, :Baz)
        return unless node.type == :const
        module_node = node.children[0]
        class_node = node.children[1]

        return class_node.to_s if module_node.nil?

        module_type_name = type_name(module_node)
        return unless module_type_name

        "#{module_type_name}::#{class_node}"
      end

      # @param node [Parser::AST::Node]
      def process_conditional(conditional_node, if_true, if_false)
        return unless conditional_node.type == :send && conditional_node.children[1] == :is_a?
        # Check if conditional node follows this pattern:
        #   s(:send,
        #     s(:send, nil, :foo), :is_a?,
        #     s(:const, nil, :Baz)),
        isa_receiver = conditional_node.children[0]
        isa_type_name = type_name(conditional_node.children[2])
        return unless isa_type_name
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
        conditional_range = Range.from_node(conditional_node)
        pins = locals.select { |pin| pin.name == variable_name && pin.presence.include?(conditional_range.start) }
        return unless pins.length == 1

        if_true[pins.first] ||= []
        if_true[pins.first] << { type: isa_type_name }
      end

      # @param node [Parser::AST::Node]
      def process_if(if_node)
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
        conditional_node = if_node.children[0]
        then_clause = if_node.children[1]
        else_clause = if_node.children[2]

        if_true = {}
        if_false = {}
        process_conditional(conditional_node, if_true, if_false)

        unless then_clause.nil?
          #
          # Add specialized locals for the then clause range
          #
          before_then_clause_loc = then_clause.location.expression.adjust(begin_pos: -1)
          before_then_clause_pos = Position.new(before_then_clause_loc.line, before_then_clause_loc.column)
          then_presence = Range.new(before_then_clause_pos,
                                    get_node_end_position(then_clause))
          if_true.each_pair do |pin, facts|
            facts.each do |fact|
              isa_type_name = fact.fetch(:type)
              # @todo Create pin#update method
              then_pin = Solargraph::Pin::LocalVariable.new(
                location: pin.location,
                closure: pin.closure,
                name: pin.name,
                assignment: pin.assignment,
                comments: pin.comments,
                presence: then_presence,
                return_type: ComplexType.try_parse(isa_type_name),
                declaration: true
              )
              locals.push(then_pin)
            end
          end
        end

        if always_breaks?(else_clause)
          unless enclosing_block_pin.nil? # TODO is break correct?
            #
            # Add specialized locals for the rest of the block
            #
            if_true.each_pair do |pin, facts|
              facts.each do |fact|
                isa_type_name = fact.fetch(:type)
                remaining_block_presence = Range.new(get_node_end_position(if_node),
                                                     get_node_end_position(enclosing_block_pin.node))
                # @todo Create pin#update method
                remaining_loop_pin = Solargraph::Pin::LocalVariable.new(
                  location: pin.location,
                  closure: pin.closure,
                  name: pin.name,
                  assignment: pin.assignment,
                  comments: pin.comments,
                  presence: remaining_block_presence,
                  return_type: ComplexType.try_parse(isa_type_name),
                  declaration: true
                )
                locals.push(remaining_loop_pin)
              end
            end
          end
        end
      end

      private

      def always_breaks?(clause_node)
        clause_node&.type == :break
      end

      attr_reader :locals

      attr_reader :enclosing_block_pin
    end
  end
end
