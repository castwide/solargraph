# frozen_string_literal: true

module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # Hash methods that return true only when the key is present
      KEY_GUARDS = %i[key? has_key? include? member?].freeze

      # Hash methods that can remove or rename a key, or change how keys
      # match, ending what a key guard proved
      KEY_REMOVERS = %i[
        delete delete_if reject! select! filter! keep_if clear replace shift
        transform_keys! compare_by_identity
      ].freeze

      # @param locals [Array<Solargraph::Pin::LocalVariable, Solargraph::Pin::KeyLookup>]
      # @param ivars [Array<Solargraph::Pin::InstanceVariable>]
      # @param enclosing_breakable_pin [Solargraph::Pin::Breakable, nil]
      # @param enclosing_compound_statement_pin [Solargraph::Pin::CompoundStatement, nil]
      def initialize locals, ivars, enclosing_breakable_pin, enclosing_compound_statement_pin
        @locals = locals
        @ivars = ivars
        @enclosing_breakable_pin = enclosing_breakable_pin
        @enclosing_compound_statement_pin = enclosing_compound_statement_pin
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
        process_key_guard(node, true_presences)
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

      # Records that 'h[k]' is not nil for the rest of the statements
      # after 'h[k] ||= v', as a true 'h.key?(k)' guard does. Chain
      # applies the fact only when 'h' is a Hash whose values can't be
      # nil, so 'v' can't be nil either.
      #
      # @param or_asgn_node [Parser::AST::Node]
      #
      # @return [void]
      def process_index_or_asgn or_asgn_node
        return unless or_asgn_node.type == :or_asgn

        lookup = or_asgn_node.children[0]
        return unless lookup.is_a?(::Parser::AST::Node) && lookup.type == :send
        return unless lookup.children[1] == :[] && lookup.children.length == 3

        body = enclosing_compound_statement_pin&.node
        parent = body && parent_of(or_asgn_node, body)
        # only statements that follow it in sequence run after it, unlike
        # e.g. what follows 'cond && (h[k] ||= v)'
        return unless parent && %i[begin kwbegin].include?(parent.type)

        presence = Range.new(get_node_end_position(or_asgn_node), get_node_end_position(parent))
        add_key_fact(or_asgn_node, lookup, [presence])
      end

      class << self
        include Logging
      end

      include Logging

      private

      # @param pin [Pin::BaseVariable]
      # @param presence [Range]
      # @param downcast_type [ComplexType, nil]
      # @param downcast_not_type [ComplexType, nil]
      #
      # @return [void]
      def add_downcast_var pin, presence:, downcast_type:, downcast_not_type:
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

      # @param node [Parser::AST::Node]
      # @param words [::Array<String>] e.g. ['pin', 'location']
      # @param writes [::Array<Position>] start positions found so far
      # @return [void]
      def collect_writes node, words, writes
        range = Range.from_node(node)
        writes << range.start if range && write_to?(node, words)
        node.children.each do |child|
          collect_writes(child, words, writes) if child.is_a?(::Parser::AST::Node)
        end
      end

      # @param node [Parser::AST::Node]
      # @param words [::Array<String>]
      # @return [Boolean]
      def write_to? node, words
        # e.g. 'pin.location ||= x' wraps a reader call in an or_asgn
        wrapped = %i[op_asgn or_asgn and_asgn].include?(node.type)
        target = wrapped ? node.children[0] : node
        return false unless target.is_a?(::Parser::AST::Node)

        variable = target.children[0].to_s
        # an attr_reader on self reads its same-named instance variable
        self_ivar = words.first == 'self' && variable == "@#{words[1]}"
        return variable == words.first || self_ivar if target.type == :ivasgn
        return words.first == variable if %i[lvasgn cvasgn].include?(target.type)
        return false unless target.type == :send

        name = target.children[1].to_s
        return false unless wrapped || name.match?(/\A[a-z_]\w*=\z/i)

        receiver_words = write_receiver(target.children[0], words)
        return false if receiver_words.nil? || receiver_words.length >= words.length

        receiver_words == words.first(receiver_words.length) && name.chomp('=') == words[receiver_words.length]
      end

      # @param node [Parser::AST::Node, nil] a setter's receiver, e.g.
      #   'location' in 'location.filename = x'
      # @param words [::Array<String>] the chain #write_to? checks
      # @return [::Array<String>, nil] the chain `node` reads, e.g. ['pin']
      #   for 'pin', ['self', 'location'] for 'location' or
      #   'self.location', or for '@location' when `words` starts at self
      def write_receiver node, words
        return ['self'] if node.nil? || node.type == :self
        # an attr_reader on self reads its same-named instance variable
        return ['self', node.children[0].to_s.delete_prefix('@')] if node.type == :ivar && words.first == 'self'
        return parse_receiver_chain(node) unless node.type == :send && (node.children[2..] || []).empty?

        base = write_receiver(node.children[0], words)
        base && (base + [node.children[1].to_s])
      end

      # Recognizes receivers shaped like 'foo', '@foo', 'foo.bar', or
      # '@foo.bar.baz' -- a chain of simple, argument-less, blockless
      # calls/variables rooted in a local, ivar, or unresolved name.
      #
      # @param node [Parser::AST::Node, nil]
      # @return [::Array<String>, nil] Dotted-word chain, e.g. ['pin',
      #   'location'], or nil if `node` doesn't have this shape.
      def parse_receiver_chain node
        return unless node.is_a?(::Parser::AST::Node)
        return [node.children[0].to_s] if %i[lvar ivar cvar].include?(node.type)
        return unless node.type == :send
        # no arguments -- children[2..] is only nil (rather than [])
        # if the start index is out of bounds, which can't happen here
        return unless (node.children[2..] || []).empty?

        method_name = node.children[1]
        return unless method_name.is_a?(Symbol)

        receiver = node.children[0]
        # bare call, e.g. `s(:send, nil, :foo)` - implicit self, so
        # 'foo' could be a local variable or a 0-arg method on self
        return [method_name.to_s] if receiver.nil?

        base = parse_receiver_chain(receiver)
        return unless base

        base + [method_name.to_s]
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
        if variable_name.start_with?('@')
          # @sg-ignore flow sensitive typing needs to handle attrs
          ivars.find { |ivar| ivar.name == variable_name && (!ivar.presence || ivar.presence.include?(position)) }
        else
          # @sg-ignore flow sensitive typing needs to handle attrs
          locals.find { |pin| pin.name == variable_name && (!pin.presence || pin.presence.include?(position)) }
        end
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
        # e.g., the '::' in '::Baz' or '::Foo::Baz' -
        #  s(:const, s(:cbase), :Baz)
        return "::#{class_node}" if module_node.type == :cbase

        module_type_name = type_name(module_node)
        return unless module_type_name

        "#{module_type_name}::#{class_node}"
      end

      # Records that 'h[k]' is not nil where 'h.key?(k)' is true. A false
      # guard proves nothing about 'h[k]', which a default proc can still
      # answer. Chain applies the fact only when 'h' is a Hash whose values
      # can't be nil, and 'h' and 'k' read variables or attr_readers.
      #
      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      #
      # @return [void]
      def process_key_guard node, true_presences
        receiver, method_name, key = node.children
        return unless KEY_GUARDS.include?(method_name) && node.children.length == 3

        # e.g. 'h[k]' with the location of 'h.key?(k)'
        add_key_fact(node, node.updated(nil, [receiver, :[], key]), true_presences)
      end

      # @param location_node [Parser::AST::Node] where the fact is learned
      # @param lookup [Parser::AST::Node] the 'h[k]' the fact is about
      # @param presences [Array<Range>]
      #
      # @return [void]
      def add_key_fact location_node, lookup, presences
        receiver, _, key = lookup.children
        receiver_steps = Pin::KeyLookup.steps_from_node(receiver)
        key_steps = Pin::KeyLookup.key_steps_from_node(key)
        statement = enclosing_compound_statement_pin
        # a method or block body is its own closure
        closure = statement.is_a?(Pin::Closure) ? statement : statement&.closure
        return unless receiver_steps && key_steps && closure

        clip_at_key_writes(presences, receiver, key).each do |presence|
          locals.push Pin::KeyLookup.new(
            location: Location.from_node(location_node),
            closure: closure,
            receiver: receiver_steps,
            key: key_steps,
            presence: presence,
            source: :flow_sensitive_typing
          )
        end
      end

      # @param node [Parser::AST::Node]
      # @param root [Parser::AST::Node]
      # @return [Parser::AST::Node, nil] the node in `root` whose child
      #   is `node`
      def parent_of node, root
        root.children.each do |child|
          next unless child.is_a?(::Parser::AST::Node)
          return root if child.equal?(node)

          found = parent_of(node, child)
          return found if found
        end
        nil
      end

      # Ends each presence of the 'h[k]' fact from a 'h.key?(k)' guard at
      # the first write to 'h' or 'k', e.g. 'h = other', or call that can
      # remove a key from 'h', e.g. 'h.delete(k)'.
      #
      # @param presences [Array<Range>]
      # @param receiver [Parser::AST::Node] e.g. 'h'
      # @param key [Parser::AST::Node] e.g. 'k'
      # @return [Array<Range>]
      def clip_at_key_writes presences, receiver, key
        body = enclosing_compound_statement_pin&.node
        # without the enclosing body, writes can't be ruled out
        return [] if body.nil?

        writes = []
        [receiver, key].each do |node|
          # e.g. ['h'], or ['self', 'table'] for an attr_reader 'table'
          words = write_receiver(node, [])
          collect_writes(body, words, writes) if words
        end
        collect_key_removals(body, receiver, writes)
        presences.map do |presence|
          cut = writes.select { |pos| presence.include?(pos) }.min
          cut ? Range.new(presence.start, cut) : presence
        end
      end

      # @param node [Parser::AST::Node]
      # @param hash [Parser::AST::Node] e.g. 'h' for 'h.delete(k)'
      # @param writes [Array<Position>] start positions found so far
      # @return [void]
      def collect_key_removals node, hash, writes
        if node.type == :send && node.children[0] == hash && KEY_REMOVERS.include?(node.children[1])
          writes << get_node_start_position(node)
        end
        node.children.each do |child|
          collect_key_removals(child, hash, writes) if child.is_a?(::Parser::AST::Node)
        end
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

      attr_reader :locals, :ivars, :enclosing_breakable_pin, :enclosing_compound_statement_pin
    end
  end
end
