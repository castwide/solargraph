module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # @param node [Parser::AST::Node]
      # @param locals [Array<Solargraph::Pin::BaseVariable>]
      def initialize(node, locals)
        @node = node
        @locals = locals
      end

      # @return [void]
      def run
        process_node(node)
      end

      def process_node(node)
        return process_if(node) if node.type == :if
        return process_or(node) if node.type == :or
      end

      def process_or(node)
        lhs = node.children[0]
        rhs = node.children[1]
        if_true = {}
        if_false = {}
        gather_facts(conditional_node, if_true, if_false)

      end

      def process_conditional(node, if_true, if_false)
        return unless node.type == :send && node.children[1] == :is_a?
        # Check if conditional node follows this pattern:
        #   s(:send,
        #     s(:send, nil, :foo), :is_a?,
        #     s(:const, nil, :Baz)),
        isa_receiver = node.children[0]
        isa_class = node.children[2]
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
        if_true[pins.first] ||= []
        if_true[pins.first] << { type: isa_type_name }
      end

      def process_if(node)
        conditional_node = node.children[0]
        then_clause = node.children[1]
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
        if_true = {}
        if_false = {}
        process_conditional(conditional_node, if_true, if_false)
        return if if_true.empty? && if_false.empty?

        return if then_clause.nil?

        before_then_clause_loc = then_clause.location.expression.adjust(begin_pos: -1)
        then_presence = Range.new(Position.new(before_then_clause_loc.line, before_then_clause_loc.column),
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

        # else_presence = Range.new(get_node_start_position(else_clause), get_node_end_position(else_clause))
      end

      private

      attr_reader :node, :locals
    end
  end
end
