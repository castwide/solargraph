module Solargraph
  module Parser
    class FlowSensitiveTyping
      include Solargraph::Parser::NodeMethods

      # @param locals [Array<Solargraph::Pin::LocalVariable, Solargraph::Pin::Parameter>]
      # @param enclosing_breakable_pin [Solargraph::Pin::Breakable, nil]
      # @param enclosing_compound_statement_pin [Solargraph::Pin::CompoundStatementable, nil]
      def initialize(locals, enclosing_breakable_pin, enclosing_compound_statement_pin)
        @locals = locals
        @enclosing_breakable_pin = enclosing_breakable_pin
        @enclosing_compound_statement_pin = enclosing_compound_statement_pin
      end

      # @param and_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_and(and_node, true_ranges = [], false_ranges = [])
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
      def process_or(or_node, true_ranges = [], false_ranges = [])
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
        # false, so't provide false ranges to assert facts on

        # can't assume if an or is true that every single condition is
        # true, so don't provide true ranges to assert facts on

        process_expression(lhs, [], [rhs_presence])
        process_expression(rhs, [], [])
      end

      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_calls(node, true_presences, false_presences)
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
      def process_if(if_node, true_ranges = [], false_ranges = [])
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

          if always_breaks?(then_clause)
            false_ranges << rest_of_breakable_body
          end

          if always_breaks?(else_clause)
            true_ranges << rest_of_breakable_body
          end
        end

        unless enclosing_compound_statement_pin.nil?
          rest_of_returnable_body = Range.new(get_node_end_position(if_node),
                                              get_node_end_position(enclosing_compound_statement_pin.node))

          #
          # if one of the clauses always leaves the compound
          # statement, we can assume things about the rest of the
          # compound statement
          #
          if always_leaves_compound_statement?(then_clause)
            false_ranges << rest_of_returnable_body
          end

          if always_leaves_compound_statement?(else_clause)
            true_ranges << rest_of_returnable_body
          end
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
      def process_while(while_node, true_ranges = [], false_ranges = [])
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

      # Find a variable pin by name and where it is used.
      #
      # Resolves our most specific view of this variable's type by
      # preferring pins created by flow-sensitive typing when we have
      # them based on the Closure and Location.
      #
      # @param pins [Array<Pin::LocalVariable>]
      # @param name [String]
      # @param closure [Pin::Closure]
      # @param location [Location]
      #
      # @return [Array<Pin::LocalVariable>]
      def self.visible_pins(pins, name, closure, location)
        logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location})" }
        pins_with_name = pins.select { |p| p.name == name }
        if pins_with_name.empty?
          logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location}) => [] - no pins with name" }
          return []
        end
        pins_with_specific_visibility = pins.select { |p| p.name == name && p.presence && p.visible_at?(closure, location) }
        if pins_with_specific_visibility.empty?
          logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location}) => #{pins_with_name} - no pins with specific visibility" }
          return pins_with_name
        end
        visible_pins_specific_to_this_closure = pins_with_specific_visibility.select { |p| p.closure == closure }
        if visible_pins_specific_to_this_closure.empty?
          logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location}) => #{pins_with_specific_visibility} - no visible pins specific to this closure (#{closure})}" }
          return pins_with_specific_visibility
        end
        flow_defined_pins = pins_with_specific_visibility.select { |p| p.presence_certain? }
        if flow_defined_pins.empty?
          logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location}) => #{visible_pins_specific_to_this_closure} - no flow-defined pins" }
          return visible_pins_specific_to_this_closure
        end

        logger.debug { "FlowSensitiveTyping#visible_pins(name=#{name}, closure=#{closure}, location=#{location}) => #{flow_defined_pins}" }

        flow_defined_pins
      end

      include Logging

      private

      # @param pin [Pin::LocalVariable]
      # @param downcast_type_name [String, :not_nil]
      # @param presence [Range]
      #
      # @return [void]
      def add_downcast_local(pin, downcast_type_name, presence)
        return_type = if downcast_type_name == :not_nil
                        pin.return_type
                      else
                        ComplexType.parse(downcast_type_name)
                      end
        exclude_return_type = downcast_type_name == :not_nil ? ComplexType::NIL : nil

        # @todo Create pin#update method
        new_pin = Solargraph::Pin::LocalVariable.new(
          presence_certain: true,
          location: pin.location,
          closure: pin.closure,
          name: pin.name,
          assignment: pin.assignment,
          comments: pin.comments,
          presence: presence,
          return_type: return_type,
          exclude_return_type: exclude_return_type,
          source: :flow_sensitive_typing
        )
        new_pin.reset_generated!
        locals.push(new_pin)
      end

      # @param facts_by_pin [Hash{Pin::LocalVariable => Array<Hash{Symbol => String}>}]
      # @param presences [Array<Range>]
      #
      # @return [void]
      def process_facts(facts_by_pin, presences)
        #
        # Add specialized locals for the rest of the block
        #
        facts_by_pin.each_pair do |pin, facts|
          facts.each do |fact|
            downcast_type_name = fact.fetch(:type, nil)
            nilp = fact.fetch(:nil, nil)
            not_nilp = fact.fetch(:not_nil, nil)
            presences.each do |presence|
              # @sg-ignore flow sensitive typing needs to handle "unless foo.nil?"
              add_downcast_local(pin, downcast_type_name, presence) unless downcast_type_name.nil?
              add_downcast_local(pin, 'nil', presence) if nilp == true
              add_downcast_local(pin, :not_nil, presence) if not_nilp == true
            end
          end
        end
      end

      # @param expression_node [Parser::AST::Node]
      # @param true_ranges [Array<Range>]
      # @param false_ranges [Array<Range>]
      #
      # @return [void]
      def process_expression(expression_node, true_ranges, false_ranges)
        process_calls(expression_node, true_ranges, false_ranges)
        process_and(expression_node, true_ranges, false_ranges)
        process_or(expression_node, true_ranges, false_ranges)
        process_variable(expression_node, true_ranges, false_ranges)
        process_if(expression_node, true_ranges, false_ranges)
      end

      # @param call_node [Parser::AST::Node]
      # @param method_name [Symbol]
      # @return [Array(String, String), nil] Tuple of rgument to
      #   function, then receiver of function if it's a variable,
      #   otherwise nil if no simple variable receiver
      def parse_call(call_node, method_name)
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
        variable_name = call_receiver.children[0].to_s if call_receiver&.type == :lvar
        return unless variable_name

        [call_arg, variable_name]
      end

      # @param isa_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_isa(isa_node)
        call_type_name, variable_name = parse_call(isa_node, :is_a?)

        return unless call_type_name

        [call_type_name, variable_name]
      end

      # @param variable_name [String]
      # @param position [Position]
      #
      # @return [Solargraph::Pin::LocalVariable, nil]
      def find_local(variable_name, position)
        pins = locals.select { |pin| pin.name == variable_name && pin.presence.include?(position) }
        # return unless pins.length == 1
        pins.first
      end

      # @param isa_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_isa(isa_node, true_presences, false_presences)
        isa_type_name, variable_name = parse_isa(isa_node)
        return if variable_name.nil? || variable_name.empty?
        # @sg-ignore Need to add nil check here
        isa_position = Range.from_node(isa_node).start

        pin = find_local(variable_name, isa_position)
        return unless pin

        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { type: isa_type_name }
        process_facts(if_true, true_presences)

        if_false = {}
        if_false[pin] ||= []
        # @todo: should add support for not_type
        # if_true[pin] << { not_type: isa_type_name }
        process_facts(if_false, false_presences)
      end

      # @param nilp_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_nilp(nilp_node)
        parse_call(nilp_node, :nil?)
      end

      # @param nilp_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_nilp(nilp_node, true_presences, false_presences)
        nilp_arg, variable_name = parse_nilp(nilp_node)
        return if variable_name.nil? || variable_name.empty?
        # if .nil? got an argument, move on, this isn't the situation
        # we're looking for and typechecking will cover any invalid
        # ones
        return unless nilp_arg.nil?
        # @sg-ignore Need to add nil check here
        nilp_position = Range.from_node(nilp_node).start

        pin = find_local(variable_name, nilp_position)
        return unless pin

        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { nil: true }
        process_facts(if_true, true_presences)

        if_false = {}
        if_false[pin] ||= []
        if_false[pin] << { not_nil: true }
        process_facts(if_false, false_presences)
      end

      # @param bang_node [Parser::AST::Node]
      # @return [Array(String, String), nil]
      def parse_bang(bang_node)
        parse_call(bang_node, :!)
      end

      # @param bang_node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      #
      # @return [void]
      def process_bang(bang_node, true_presences, false_presences)
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
      def parse_variable(var_node)
        return if var_node.children.length != 1

        var_node.children[0]&.to_s
      end

      # @return [void]
      # @param node [Parser::AST::Node]
      # @param true_presences [Array<Range>]
      # @param false_presences [Array<Range>]
      def process_variable(node, true_presences, false_presences)
        return unless [:lvar, :ivar, :cvar, :gvar].include?(node.type)

        variable_name = parse_variable(node)
        return if variable_name.nil?

        # @sg-ignore Need to add nil check here
        var_position = Range.from_node(node).start

        pin = find_local(variable_name, var_position)
        return unless pin

        if_true = {}
        if_true[pin] ||= []
        if_true[pin] << { not_nil: true }
        process_facts(if_true, true_presences)

        if_false = {}
        if_false[pin] ||= []
        if_false[pin] << { nil: true }
        process_facts(if_false, false_presences)
      end

      # @param node [Parser::AST::Node]
      #
      # @return [String, nil]
      def type_name(node)
        # e.g.,
        #  s(:const, nil, :Baz)
        return unless node&.type == :const
        module_node = node.children[0]
        class_node = node.children[1]

        return class_node.to_s if module_node.nil?

        module_type_name = type_name(module_node)
        return unless module_type_name

        "#{module_type_name}::#{class_node}"
      end

      # @param clause_node [Parser::AST::Node, nil]
      # @sg-ignore need boolish support for ? methods
      def always_breaks?(clause_node)
        clause_node&.type == :break
      end

      # @param clause_node [Parser::AST::Node, nil]
      def always_leaves_compound_statement?(clause_node)
        # https://docs.ruby-lang.org/en/2.2.0/keywords_rdoc.html
        [:return, :raise, :next, :redo, :retry].include?(clause_node&.type)
      end

      attr_reader :locals

      attr_reader :enclosing_breakable_pin, :enclosing_compound_statement_pin
    end
  end
end
