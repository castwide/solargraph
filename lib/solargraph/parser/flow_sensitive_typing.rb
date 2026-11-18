# frozen_string_literal: true

module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # Nodes that assign a local variable, e.g. 'pin = other' or the 'pin'
      # in 'in [pin]': each ends the narrowing of 'pin.location'
      LOCAL_BINDINGS = %i[lvasgn match_var].freeze

      # Parameter nodes, e.g. the 'pin' in '|pin|': a block with one is a
      # new scope, where 'pin.location' reads another 'pin', but the outer
      # 'pin' is the same again after the block
      PARAMETERS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg procarg0].freeze

      # Nodes whose body can run again, so a write late in the body changes
      # what an earlier read in the body sees on the next pass
      REPEATING = %i[while until while_post until_post for block numblock].freeze

      # @param locals [Array<Solargraph::Pin::LocalVariable, Solargraph::Pin::ExpressionNarrowing>]
      # @param ivars [Array<Solargraph::Pin::InstanceVariable>]
      # @param enclosing_breakable_pin [Solargraph::Pin::Breakable, nil]
      # @param enclosing_compound_statement_pin [Solargraph::Pin::CompoundStatement, nil]
      # @param closure [Solargraph::Pin::Closure, nil] the enclosing closure,
      #   where narrowings of expressions such as 'pin.location' apply
      def initialize locals, ivars, enclosing_breakable_pin, enclosing_compound_statement_pin, closure: nil
        @locals = locals
        @ivars = ivars
        @enclosing_breakable_pin = enclosing_breakable_pin
        @enclosing_compound_statement_pin = enclosing_compound_statement_pin
        @closure = closure
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

        process_expression(conditional_node, true_ranges, false_ranges)
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

      # @param pin [Pin::BaseVariable, Pin::ExpressionNarrowing] see #subject_pin
      # @param presence [Range]
      # @param downcast_type [ComplexType, nil]
      # @param downcast_not_type [ComplexType, nil]
      #
      # @return [void]
      def add_downcast_var pin, presence:, downcast_type:, downcast_not_type:
        if pin.is_a?(Pin::ExpressionNarrowing)
          locals.push Pin::ExpressionNarrowing.new(steps: pin.steps, presence: presence,
                                                   exclude_return_type: downcast_not_type,
                                                   intersection_return_type: downcast_type,
                                                   closure: pin.closure, location: pin.location,
                                                   source: :flow_sensitive_typing)
          return
        end

        # @sg-ignore Unresolved call to downcast on Solargraph::Pin::BaseVariable,
        #   Solargraph::Pin::ExpressionNarrowing
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

      # @param facts_by_pin [Hash{Pin::BaseVariable, Pin::ExpressionNarrowing => Array<Hash{:type, :not_type => ComplexType}>}]
      # @param presences [Array<Range>]
      #
      # @return [void]
      def process_facts facts_by_pin, presences
        #
        # Add specialized vars for the rest of the block
        #
        facts_by_pin.each_pair do |pin, facts|
          pin_presences = clip_at_writes(pin, presences)
          facts.each do |fact|
            downcast_type = fact.fetch(:type, nil)
            downcast_not_type = fact.fetch(:not_type, nil)
            pin_presences.each do |presence|
              add_downcast_var(pin,
                               presence: presence,
                               downcast_type: downcast_type,
                               downcast_not_type: downcast_not_type)
            end
          end
        end
      end

      # Ends each presence of an expression narrowing, e.g. of
      # 'pin.location' or 'location.filename', at the first write that can
      # change what the expression returns, e.g. 'pin = other' or
      # 'pin.location = nil', or at the start of a loop or block inside the
      # presence that contains such a write, and leaves out each block whose
      # parameter shadows the variable the expression reads, e.g.
      # 'each { |pin| ... }'.
      #
      # @param pin [Pin::BaseVariable, Pin::ExpressionNarrowing]
      # @param presences [Array<Range>]
      # @sg-ignore Declared return type ::Array<::Solargraph::Range> does not
      #   match inferred type ::Array<::Solargraph::Range>, ::Array,
      #   ::Array<::Array> for
      #   Solargraph::Parser::FlowSensitiveTyping#clip_at_writes
      # @return [Array<Range>]
      def clip_at_writes pin, presences
        return presences unless pin.is_a?(Pin::ExpressionNarrowing)
        # without the enclosing body, writes can't be ruled out
        return [] if enclosing_compound_statement_pin&.node.nil?

        # @type [::Array<::Array<Position>>]
        writes = []
        collect_writes(enclosing_compound_statement_pin.node, pin.steps, writes, [])
        # @type [::Array<Range>]
        shadows = []
        root = pin.steps.first
        # @sg-ignore Unresolved call to last
        collect_shadows(enclosing_compound_statement_pin.node, root.last, shadows) if root&.first == :lvar
        presences.flat_map do |presence|
          cut = writes.filter_map { |positions| positions.find { |pos| presence.include?(pos) } }.min
          range = cut ? Range.new(presence.start, cut) : presence
          # @sg-ignore Unresolved call to flat_map
          shadows.reduce([range]) { |pieces, shadow| pieces.flat_map { |piece| outside(piece, shadow) } }
        end
      end

      # @param node [Parser::AST::Node]
      # @param name [Symbol] e.g. :pin for 'pin.location'
      # @param shadows [::Array<Range>] gets each block with a parameter
      #   named `name`, e.g. 'each { |pin| ... }'
      # @return [void]
      def collect_shadows node, name, shadows
        range = Range.from_node(node)
        shadows.push range if range && node.type == :block && parameter?(node.children[1], name)
        node.children.each do |child|
          collect_shadows(child, name, shadows) if child.is_a?(::Parser::AST::Node)
        end
      end

      # @param node [Parser::AST::Node, Object] e.g. a block's '|i, (j, k)|'
      # @param name [Symbol]
      # @return [Boolean] true if `node` declares a parameter named `name`
      def parameter? node, name
        return false unless node.is_a?(::Parser::AST::Node)
        return true if PARAMETERS.include?(node.type) && node.children[0] == name

        node.children.any? { |child| parameter?(child, name) }
      end

      # @param range [Range] a presence
      # @param hole [Range] a block whose parameter shadows what `range`
      #   narrows
      # @return [::Array<Range>] the parts of `range` before and after
      #   `hole`, or `range` itself unless `hole` starts inside it
      def outside range, hole
        return [range] unless range.include?(hole.start)

        before = Range.new(range.start, hole.start)
        range.include?(hole.ending) ? [before, Range.new(hole.ending, range.ending)] : [before]
      end

      # @param node [Parser::AST::Node]
      # @param steps [::Array<::Array>] e.g. [[:lvar, :pin], [:call, :location]]
      # @param writes [::Array<::Array<Position>>] for each write found so
      #   far, the starts of its enclosing REPEATING nodes, outermost first,
      #   then the start of the write
      # @param repeats [::Array<Position>] starts of the REPEATING nodes
      #   enclosing `node`, outermost first
      # @return [void]
      def collect_writes node, steps, writes, repeats
        range = Range.from_node(node)
        writes << [*repeats, range.start] if range && write_to?(node, steps)
        repeats += [range.start] if range && REPEATING.include?(node.type)
        node.children.each do |child|
          collect_writes(child, steps, writes, repeats) if child.is_a?(::Parser::AST::Node)
        end
      end

      # @param node [Parser::AST::Node]
      # @param steps [::Array<::Array>]
      # @return [Boolean]
      def write_to? node, steps
        # e.g. 'pin.location ||= x' wraps a reader call in an or_asgn
        wrapped = %i[op_asgn or_asgn and_asgn].include?(node.type)
        target = wrapped ? node.children[0] : node
        return false unless target.is_a?(::Parser::AST::Node)

        root = steps.first
        return false if root.nil?

        variable = target.children[0]
        return root == [:lvar, variable] if LOCAL_BINDINGS.include?(target.type)
        # an attr_reader on self reads its same-named instance variable
        return [[:ivar, variable], [:self_call, variable.to_s.delete_prefix('@').to_sym]].include?(root) if target.type == :ivasgn
        # e.g. 'pin.location = x' or 'pin&.location = x'
        return false unless %i[send csend].include?(target.type)

        name = target.children[1].to_s
        return false unless wrapped || name.match?(/\A[a-z_]\w*=\z/i)

        receiver = write_receiver(target.children[0], root)
        return false if receiver.nil?

        attribute = name.chomp('=').to_sym
        # an attr_writer on self assigns its same-named instance variable
        return true if receiver.empty? && root == [:ivar, :"@#{attribute}"]

        written = receiver + [[receiver.empty? ? :self_call : :call, attribute]]
        steps.first(written.length) == written
      end

      # @param node [Parser::AST::Node, Object, nil] a setter's receiver,
      #   e.g. 'location' in 'location.filename = x'
      # @param root [::Array] the first of the steps #write_to? checks
      # @return [::Array<::Array>, nil] the steps `node` reads, [] for
      #   self, or [[:self_call, :location]] for '@location' when `root` is
      #   a call on self
      def write_receiver node, root
        return [] if node.nil?
        return unless node.is_a?(::Parser::AST::Node)
        return [] if node.type == :self
        # an attr_reader on self reads its same-named instance variable
        return [[:self_call, node.children[0].to_s.delete_prefix('@').to_sym]] if node.type == :ivar && root.first == :self_call
        return Pin::ExpressionNarrowing.steps_from_node(node) unless node.type == :send && node.children.length == 2

        base = write_receiver(node.children[0], root)
        base && (base + [[base.empty? ? :self_call : :call, node.children[1]]])
      end

      # @param expression_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_expression expression_node, true_ranges, false_ranges
        process_calls(expression_node, true_ranges, false_ranges)
        process_and(expression_node, true_ranges, false_ranges)
        process_or(expression_node, true_ranges, false_ranges)
        process_variable(expression_node, true_ranges, false_ranges)
        process_call_chain(expression_node, true_ranges, false_ranges)
      end

      # @param call_node [Parser::AST::Node]
      # @param method_name [Symbol]
      # @return [Array(String, Parser::AST::Node), nil] Tuple of argument
      #   to function, then the receiver, otherwise nil if there is no
      #   receiver
      def parse_call call_node, method_name
        return unless call_node&.type == :send && call_node.children[1] == method_name
        # Check if conditional node follows this pattern:
        #   s(:send,
        #     s(:send, nil, :foo), :is_a?,
        #     s(:const, nil, :Baz)),
        #
        call_receiver = call_node.children[0]
        call_arg = type_name(call_node.children[2])
        return unless call_receiver

        [call_arg, call_receiver]
      end

      # @param isa_node [Parser::AST::Node]
      # @return [Array(String, Parser::AST::Node), nil]
      def parse_isa isa_node
        call_type_name, receiver = parse_call(isa_node, :is_a?)

        return unless call_type_name

        [call_type_name, receiver]
      end

      # @param variable_name [String]
      # @param position [Position]
      #
      # @sg-ignore Solargraph::Parser::FlowSensitiveTyping#find_var
      #   return type could not be inferred
      # @return [Solargraph::Pin::LocalVariable, Solargraph::Pin::InstanceVariable, nil]
      def find_var variable_name, position
        if variable_name.start_with?('@')
          ivars.find { |ivar| ivar.name == variable_name && (!ivar.presence || ivar.presence.include?(position)) }
        else
          locals.find { |pin| pin.name == variable_name && (!pin.presence || pin.presence.include?(position)) }
        end
      end

      # Finds the variable, or builds a template of the expression
      # narrowing, that facts about `node` get recorded on, e.g. for 'pin',
      # '@pin.location' or a bare 'location', a call on self. Only variables
      # and argument-less calls on them qualify; #add_downcast_var copies a
      # template with each presence.
      #
      # @param node [Parser::AST::Node] e.g. the node for 'pin.location'
      # @param position [Position]
      # @return [Pin::LocalVariable, Pin::InstanceVariable, Pin::ExpressionNarrowing, nil]
      def subject_pin node, position
        steps = Pin::ExpressionNarrowing.steps_from_node(node)
        root = steps&.first
        # an index step, e.g. 'h[:k]', carries a key
        return if steps.nil? || root.nil? || root.first == :cvar || steps.any? { |step| step.length > 2 }
        return find_var(root.last.to_s, position) if steps.length == 1 && root.first != :self_call

        location = Location.from_node(node)
        return if closure.nil? || location.nil?

        Pin::ExpressionNarrowing.new(steps: steps, presence: location.range, closure: closure,
                                     location: location, source: :flow_sensitive_typing)
      end

      # @param isa_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_isa isa_node, true_presences, false_presences
        isa_type_name, receiver = parse_isa(isa_node)
        return if receiver.nil?
        # @sg-ignore Need to add nil check here
        isa_position = Range.from_node(isa_node).start

        # @sg-ignore Wrong argument type for
        #   Solargraph::Parser::FlowSensitiveTyping#subject_pin: node expected
        #   Parser::AST::Node, received String
        pin = subject_pin(receiver, isa_position)
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
      # @return [Array(String, Parser::AST::Node), nil]
      def parse_nilp nilp_node
        parse_call(nilp_node, :nil?)
      end

      # @param nilp_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_nilp nilp_node, true_presences, false_presences
        nilp_arg, receiver = parse_nilp(nilp_node)
        return if receiver.nil?
        # if .nil? got an argument, move on, this isn't the situation
        # we're looking for and typechecking will cover any invalid
        # ones
        return unless nilp_arg.nil?
        # @sg-ignore Need to add nil check here
        nilp_position = Range.from_node(nilp_node).start

        # @sg-ignore Wrong argument type for
        #   Solargraph::Parser::FlowSensitiveTyping#subject_pin: node expected
        #   Parser::AST::Node, received String
        pin = subject_pin(receiver, nilp_position)
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

      # Handles a truthy check on a call chain, e.g. 'pin.location' in
      # 'return nil unless pin.location', or on a bare self call, e.g.
      # 'location'; bare vars go to #process_variable.
      #
      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_call_chain node, true_presences, false_presences
        return unless node.type == :send
        # already handled (with inverted true/false semantics) by
        # process_nilp/process_bang
        return if %i[nil? !].include?(node.children[1])

        range = Range.from_node(node)
        return unless range

        pin = subject_pin(node, range.start)
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
        # e.g., the '::' in '::Baz' or '::Foo::Baz' -
        #  s(:const, s(:cbase), :Baz)
        return "::#{class_node}" if module_node.type == :cbase

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

      attr_reader :locals, :ivars, :enclosing_breakable_pin, :enclosing_compound_statement_pin, :closure
    end
  end
end
