# frozen_string_literal: true

module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # @param locals [Array<Solargraph::Pin::LocalVariable>]
      # @param ivars [Array<Solargraph::Pin::InstanceVariable>]
      # @param enclosing_breakable_pin [Solargraph::Pin::Breakable, nil]
      # @param enclosing_compound_statement_pin [Solargraph::Pin::CompoundStatement, nil]
      # @param only_downcast_these_names [Array<String>, nil] If given,
      #   only apply a downcast to variables with these names, ignoring
      #   any other variable the analyzed condition happens to mention.
      def initialize locals, ivars, enclosing_breakable_pin, enclosing_compound_statement_pin,
                     only_downcast_these_names: nil
        @locals = locals
        @ivars = ivars
        @enclosing_breakable_pin = enclosing_breakable_pin
        @enclosing_compound_statement_pin = enclosing_compound_statement_pin
        @only_downcast_these_names = only_downcast_these_names
      end

      # Assert what a true/false expression implies over the given ranges.
      # Public for instances configured with only_downcast_these_names.
      #
      # @param expression_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_expression expression_node, true_ranges, false_ranges
        process_calls(expression_node, true_ranges, false_ranges)
        process_and(expression_node, true_ranges, false_ranges)
        process_or(expression_node, true_ranges, false_ranges)
        process_parentheses(expression_node, true_ranges, false_ranges)
        process_assignment(expression_node, true_ranges, false_ranges)
        process_variable(expression_node, true_ranges, false_ranges)
      end

      # @param and_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_and and_node, true_ranges = [], false_ranges = []
        return unless and_node.type == :and

        # @type [Parser::AST::Node]
        lhs = and_node.children[0]
        # @type [Parser::AST::Node]
        rhs = and_node.children[1]

        before_rhs_loc = rhs.location.expression.adjust(begin_pos: -1)
        before_rhs_pos = Position.new(before_rhs_loc.line, before_rhs_loc.column)

        rhs_presence = Range.new(before_rhs_pos,
                                 get_node_end_position(rhs))

        # can't assume if an and is false that every single condition
        # is false, so don't provide any false ranges to assert facts
        # on
        process_expression(lhs, true_ranges + [rhs_presence], [])
        process_expression(rhs, true_ranges, [])
      end

      # @param or_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_or or_node, true_ranges = [], false_ranges = []
        return unless or_node.type == :or

        # @type [Parser::AST::Node]
        lhs = or_node.children[0]
        # @type [Parser::AST::Node]
        rhs = or_node.children[1]

        before_rhs_loc = rhs.location.expression.adjust(begin_pos: -1)
        before_rhs_pos = Position.new(before_rhs_loc.line, before_rhs_loc.column)

        rhs_presence = Range.new(before_rhs_pos,
                                 get_node_end_position(rhs))

        # can assume if an or is false that every single condition is
        # false, so provide false ranges to assert facts on

        # can't assume if an or is true that every single condition is
        # true, so don't provide true ranges to assert facts on

        process_expression(lhs, [], false_ranges + [rhs_presence])
        process_expression(rhs, [], false_ranges)
      end

      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_calls node, true_presences, false_presences
        return unless node.type == :send

        process_isa(node, true_presences, false_presences)
        process_nilp(node, true_presences, false_presences)
        process_bang(node, true_presences, false_presences)
      end

      # @param if_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_if if_node, true_ranges = [], false_ranges = []
        return if if_node.type != :if

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
        # @type [Parser::AST::Node, nil]
        then_clause = if_node.children[1]
        # @type [Parser::AST::Node, nil]
        else_clause = if_node.children[2]

        unless enclosing_breakable_pin.nil?
          rest_of_breakable_body = Range.new(get_node_end_position(if_node),
                                             get_node_end_position(enclosing_breakable_pin.node))

          false_ranges << rest_of_breakable_body if always_breaks?(then_clause)

          true_ranges << rest_of_breakable_body if always_breaks?(else_clause)
        end

        unless enclosing_compound_statement_pin.node.nil?
          rest_of_returnable_body = Range.new(get_node_end_position(if_node),
                                              get_node_end_position(enclosing_compound_statement_pin.node))

          #
          # if one of the clauses always leaves the compound
          # statement, we can assume things about the rest of the
          # compound statement
          #
          false_ranges << rest_of_returnable_body if always_leaves_compound_statement?(then_clause)

          true_ranges << rest_of_returnable_body if always_leaves_compound_statement?(else_clause)
        end

        assert_after_skipped_or_asgn(conditional_node, then_clause, else_clause)

        unless then_clause.nil?
          #
          # If the condition is true we can assume things about the then clause
          #
          before_then_clause_loc = then_clause.location.expression.adjust(begin_pos: -1)
          before_then_clause_pos = Position.new(before_then_clause_loc.line, before_then_clause_loc.column)
          true_ranges << Range.new(before_then_clause_pos,
                                   get_node_end_position(then_clause))
        end

        unless else_clause.nil?
          #
          # If the condition is true we can assume things about the else clause
          #
          before_else_clause_loc = else_clause.location.expression.adjust(begin_pos: -1)
          before_else_clause_pos = Position.new(before_else_clause_loc.line, before_else_clause_loc.column)
          false_ranges << Range.new(before_else_clause_pos,
                                    get_node_end_position(else_clause))
        end

        return if conditional_node.nil?

        process_expression(conditional_node, true_ranges, false_ranges)

        process_guarded_reassignment(if_node, conditional_node, then_clause, else_clause)
      end

      # @param while_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_while while_node, true_ranges = [], false_ranges = []
        return if while_node.type != :while

        #
        # See if we can refine a type based on the result of 'if foo.nil?'
        #
        # [3] pry(main)> Parser::CurrentRuby.parse("while a; b; c; end")
        # => s(:while,
        #   s(:send, nil, :a),
        #   s(:begin,
        #     s(:send, nil, :b),
        #     s(:send, nil, :c)))
        # [4] pry(main)>
        conditional_node = while_node.children[0]
        # @type [Parser::AST::Node, nil]
        do_clause = while_node.children[1]

        unless do_clause.nil?
          #
          # If the condition is true we can assume things about the do clause
          #
          before_do_clause_loc = do_clause.location.expression.adjust(begin_pos: -1)
          before_do_clause_pos = Position.new(before_do_clause_loc.line, before_do_clause_loc.column)
          true_ranges << Range.new(before_do_clause_pos,
                                   get_node_end_position(do_clause))
        end

        process_expression(conditional_node, true_ranges, false_ranges)
      end

      class << self
        include Logging
      end

      include Logging

      private

      # For `tasks = ['a'] if tasks.nil?`, code after the conditional also
      # gets the else-branch facts; the firing path is already handled by
      # unioning in the assignment pin. Restricted to names the clause
      # definitely reassigns, or `x.nil? || y.nil?` would narrow `y` too.
      #
      # @param if_node [Parser::AST::Node]
      # @param conditional_node [Parser::AST::Node]
      # @param then_clause [Parser::AST::Node, nil]
      # @param else_clause [Parser::AST::Node, nil]
      #
      # @return [void]
      def process_guarded_reassignment if_node, conditional_node, then_clause, else_clause
        compound_statement_node = enclosing_compound_statement_pin&.node
        return if compound_statement_node.nil?

        rest_of_compound_statement = Range.new(get_node_end_position(if_node),
                                               get_node_end_position(compound_statement_node))

        # the then clause ran only when the condition was true, so the
        # path that preserved the original value is the false one -
        # and vice versa for the else clause
        assert_after_guard(conditional_node, definitely_assigned_names(then_clause),
                           [], [rest_of_compound_statement])
        assert_after_guard(conditional_node, definitely_assigned_names(else_clause),
                           [rest_of_compound_statement], [])
      end

      # A leaving guard inside a `x ||= ...` body still dominates the
      # code after the ||=, but only for x: the body is skipped
      # exactly when x was truthy, so both paths reach the same
      # conclusion about x. No other variable gets that guarantee,
      # hence the restriction to x by name.
      #
      # @param conditional_node [Parser::AST::Node, nil]
      # @param then_clause [Parser::AST::Node, nil]
      # @param else_clause [Parser::AST::Node, nil]
      #
      # @return [void]
      def assert_after_skipped_or_asgn conditional_node, then_clause, else_clause
        return if conditional_node.nil?

        or_asgn_pin = enclosing_compound_statement_pin
        return if or_asgn_pin.nil?

        or_asgn_node = or_asgn_pin.node
        return if or_asgn_node.nil?
        return unless or_asgn_node.type == :or_asgn

        parent = or_asgn_pin.compound_statement
        return if parent.nil?

        parent_node = parent.node
        return if parent_node.nil?

        lhs_node = or_asgn_node.children[0]
        return if lhs_node.nil?

        name = lhs_node.children[0].to_s
        rest = Range.new(get_node_end_position(or_asgn_node), get_node_end_position(parent_node))

        assert_after_guard(conditional_node, [name], [], [rest]) if always_leaves_compound_statement?(then_clause)
        assert_after_guard(conditional_node, [name], [rest], []) if always_leaves_compound_statement?(else_clause)
      end

      # Applies, not checks: `names` is already assigned unconditionally
      # over these ranges, so the narrowed types take effect as fact.
      #
      # @param conditional_node [Parser::AST::Node]
      # @param names [Array<String>]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def assert_after_guard conditional_node, names, true_ranges, false_ranges
        return if names.empty?

        FlowSensitiveTyping.new(locals, ivars, enclosing_breakable_pin, enclosing_compound_statement_pin,
                                only_downcast_these_names: names)
                           .process_expression(conditional_node, true_ranges, false_ranges)
      end

      # Names this clause assigns on every path. Only unconditional plain
      # assignments count; `||=`/`+=` keep the previous value in play.
      #
      # @param clause_node [Parser::AST::Node, nil]
      #
      # @return [Array<String>]
      def definitely_assigned_names clause_node
        return [] if clause_node.nil?

        case clause_node.type
        when :lvasgn, :ivasgn
          [clause_node.children[0].to_s]
        when :begin, :kwbegin
          clause_node.children.flat_map { |child| definitely_assigned_names(child) }
        else
          []
        end
      end

      # @param pin [Pin::BaseVariable]
      # @param presence [Range]
      # @param downcast_type [ComplexType, nil]
      # @param downcast_not_type [ComplexType, nil]
      #
      # @return [void]
      def add_downcast_var pin, presence:, downcast_type:, downcast_not_type:
        return if only_downcast_these_names && !only_downcast_these_names.include?(pin.name)

        new_pin = pin.downcast(exclude_return_type: downcast_not_type,
                               intersection_return_type: downcast_type,
                               source: :flow_sensitive_typing,
                               presence: presence)
        if pin.is_a?(Pin::LocalVariable)
          locals.push(new_pin)
        elsif pin.is_a?(Pin::InstanceVariable)
          ivars.push(new_pin)
        else
          raise "Tried to add invalid pin type #{pin.class} in FlowSensitiveTyping"
        end
      end

      # @param facts_by_pin [Hash{Pin::BaseVariable => Array<Hash{:type, :not_type => ComplexType}>}]
      # @param presences [Array<Range>]
      #
      # @return [void]
      def process_facts facts_by_pin, presences
        #
        # Add specialized vars for the rest of the block
        #
        facts_by_pin.each_pair do |pin, facts|
          facts.each do |fact|
            downcast_type = fact.fetch(:type, nil)
            downcast_not_type = fact.fetch(:not_type, nil)
            presences.each do |presence|
              add_downcast_var(pin,
                               presence: presence,
                               downcast_type: downcast_type,
                               downcast_not_type: downcast_not_type)
            end
          end
        end
      end

      # `(foo)` parses as a one-child :begin wrapping the expression,
      # which is how an assignment used as a condition normally shows
      # up: `if (md = foo.match(...))`.  A multi-statement :begin
      # takes its truthiness from the last statement, which isn't
      # worth handling here.
      #
      # @param node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_parentheses node, true_ranges, false_ranges
        return unless node.type == :begin && node.children.length == 1

        child = node.children[0]
        return unless child.is_a?(::Parser::AST::Node)

        # @sg-ignore flow sensitive typing doesn't narrow `child` past the guard above
        process_expression(child, true_ranges, false_ranges)
      end

      # An assignment used as a condition - `if (md = foo.match(...))`
      # - evaluates to the value assigned, so the branches tell us the
      # same thing about the variable that a bare reference to it
      # would.
      #
      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_assignment node, true_presences, false_presences
        return unless %i[lvasgn ivasgn].include?(node.type)

        variable_name = node.children[0]&.to_s
        return if variable_name.nil? || variable_name.empty?

        # look the variable up at the end of its own assignment, where
        # the new value has become visible
        pin = find_var(variable_name, get_node_end_position(node))
        return unless pin

        # @type Hash{Pin::BaseVariable => Array<Hash{Symbol => ComplexType}>}
        if_true = { pin => [{ not_type: ComplexType::NIL }] }
        process_facts(if_true, true_presences)

        # @type Hash{Pin::BaseVariable => Array<Hash{Symbol => ComplexType}>}
        if_false = { pin => [{ type: ComplexType.parse('nil, false') }] }
        process_facts(if_false, false_presences)
      end

      # @param call_node [Parser::AST::Node]
      # @param method_name [Symbol]
      # @return [Array(String, String), nil] Tuple of rgument to
      #   function, then receiver of function if it's a variable,
      #   otherwise nil if no simple variable receiver
      def parse_call call_node, method_name
        return unless call_node&.type == :send && call_node.children[1] == method_name
        # Check if conditional node follows this pattern:
        #   s(:send,
        #     s(:send, nil, :foo), :is_a?,
        #     s(:const, nil, :Baz)),
        #
        call_receiver = call_node.children[0]
        call_arg = type_name(call_node.children[2])

        # check if call_receiver looks like this:
        #  s(:send, nil, :foo)
        # and set variable_name to :foo
        if call_receiver&.type == :send && call_receiver.children[0].nil? && call_receiver.children[1].is_a?(Symbol)
          variable_name = call_receiver.children[1].to_s
        end
        # or like this:
        # (lvar :repr)
        variable_name = call_receiver.children[0].to_s if %i[lvar ivar].include?(call_receiver&.type)
        return unless variable_name

        [call_arg, variable_name]
      end

      # @param isa_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_isa isa_node
        call_type_name, variable_name = parse_call(isa_node, :is_a?)

        return unless call_type_name

        [call_type_name, variable_name]
      end

      # @param variable_name [String]
      # @param position [Position]
      #
      # @sg-ignore Solargraph::Parser::FlowSensitiveTyping#find_var
      #   return type could not be inferred
      # @return [Solargraph::Pin::LocalVariable, Solargraph::Pin::InstanceVariable, nil]
      def find_var variable_name, position
        pins = variable_name.start_with?('@') ? ivars : locals
        # Latest-starting presence wins: an original declaration and a
        # later reassignment can both cover this position. Skip pins
        # still evaluating their own RHS (`baz ||= begin ... end`).
        matches = pins.select do |pin|
          next false unless pin.name == variable_name
          # @sg-ignore flow sensitive typing needs to handle attrs
          next false unless !pin.presence || pin.presence.include?(position)

          other_loc = Location.new(pin.location&.filename, Range.new(position, position))
          !pin.within_own_assignment?(other_loc)
        end
        matches.max_by { |pin| pin.presence&.start || Position.new(0, 0) }
      end

      # @param isa_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_isa isa_node, true_presences, false_presences
        isa_type_name, variable_name = parse_isa(isa_node)
        return if variable_name.nil? || variable_name.empty?
        # @sg-ignore Need to add nil check here
        isa_position = Range.from_node(isa_node).start

        pin = find_var(variable_name, isa_position)
        return unless pin

        # @type Hash{Pin::BaseVariable => Array<Hash{Symbol => ComplexType}>}
        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { type: ComplexType.parse(isa_type_name) }
        process_facts(if_true, true_presences)

        # @type Hash{Pin::BaseVariable => Array<Hash{Symbol => ComplexType}>}
        if_false = {}
        if_false[pin] ||= []
        if_false[pin] << { not_type: ComplexType.parse(isa_type_name) }
        process_facts(if_false, false_presences)
      end

      # @param nilp_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_nilp nilp_node
        parse_call(nilp_node, :nil?)
      end

      # @param nilp_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_nilp nilp_node, true_presences, false_presences
        nilp_arg, variable_name = parse_nilp(nilp_node)
        return if variable_name.nil? || variable_name.empty?
        # if .nil? got an argument, move on, this isn't the situation
        # we're looking for and typechecking will cover any invalid
        # ones
        return unless nilp_arg.nil?
        # @sg-ignore Need to add nil check here
        nilp_position = Range.from_node(nilp_node).start

        pin = find_var(variable_name, nilp_position)
        return unless pin

        # @type Hash{Pin::LocalVariable => Array<Hash{Symbol => ComplexType}>}
        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { type: ComplexType::NIL }
        process_facts(if_true, true_presences)

        # @type Hash{Pin::LocalVariable => Array<Hash{Symbol => ComplexType}>}
        if_false = {}
        if_false[pin] ||= []
        if_false[pin] << { not_type: ComplexType::NIL }
        process_facts(if_false, false_presences)
      end

      # @param bang_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_bang bang_node
        parse_call(bang_node, :!)
      end

      # @param bang_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_bang bang_node, true_presences, false_presences
        # pry(main)> require 'parser/current'; Parser::CurrentRuby.parse("!2")
        # => s(:send,
        #   s(:int, 2), :!)
        #       end
        return unless bang_node.type == :send && bang_node.children[1] == :!

        receiver = bang_node.children[0]

        # swap the two presences
        process_expression(receiver, false_presences, true_presences)
      end

      # @param var_node [Parser::AST::Node]
      #
      # @return [String, nil] Variable name referenced
      def parse_variable var_node
        return if var_node.children.length != 1

        var_node.children[0]&.to_s
      end

      # @return [void]
      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      def process_variable node, true_presences, false_presences
        return unless %i[lvar ivar cvar gvar].include?(node.type)

        variable_name = parse_variable(node)
        return if variable_name.nil?

        # @sg-ignore Need to add nil check here
        var_position = Range.from_node(node).start

        pin = find_var(variable_name, var_position)
        return unless pin

        # @type Hash{Pin::LocalVariable => Array<Hash{Symbol => ComplexType}>}
        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { not_type: ComplexType::NIL }
        process_facts(if_true, true_presences)

        # @type Hash{Pin::LocalVariable => Array<Hash{Symbol => ComplexType}>}
        if_false = {}
        if_false[pin] ||= []
        if_false[pin] << { type: ComplexType.parse('nil, false') }
        process_facts(if_false, false_presences)
      end

      # @param node [Parser::AST::Node]
      #
      # @return [String, nil]
      def type_name node
        # e.g.,
        #  s(:const, nil, :Baz)
        return unless node&.type == :const
        # @type [Parser::AST::Node, nil]
        module_node = node.children[0]
        # @type [Parser::AST::Node, nil]
        class_node = node.children[1]

        return class_node.to_s if module_node.nil?

        module_type_name = type_name(module_node)
        return unless module_type_name

        "#{module_type_name}::#{class_node}"
      end

      # @param clause_node [Parser::AST::Node, nil]
      # @sg-ignore need boolish support for ? methods
      def always_breaks? clause_node
        clause_node&.type == :break
      end

      # @param clause_node [Parser::AST::Node, nil]
      def always_leaves_compound_statement? clause_node
        # https://docs.ruby-lang.org/en/2.2.0/keywords_rdoc.html
        %i[return raise next redo retry].include?(clause_node&.type)
      end

      attr_reader :locals, :ivars, :enclosing_breakable_pin, :enclosing_compound_statement_pin,
                  :only_downcast_these_names
    end
  end
end
