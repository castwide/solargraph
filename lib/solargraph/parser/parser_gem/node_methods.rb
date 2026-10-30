# frozen_string_literal: true

require 'parser'
require 'ast'

# https://github.com/whitequark/parser
# rubocop:disable Metrics/ModuleLength
module Solargraph
  module Parser
    module ParserGem
      module NodeMethods
        module_function

        # @param node [Parser::AST::Node, nil]
        # @return [String]
        def unpack_name node
          pack_name(node).join('::')
        end

        # @param node [Parser::AST::Node, nil]
        # @return [Array<String, Symbol, Numeric>]
        def pack_name node
          # @type [Array<String, Symbol, Numeric>]
          parts = []
          if node.is_a?(AST::Node)
            node.children.each do |n|
              # s(:const, scope, :Name) packs to [*scope, :Name]; a leading
              # s(:cbase) roots it with ''. Callers may pass other nodes, e.g. a
              # constant's s(:str, "x") assignment, whose scalar children are kept.
              case n
              in ::AST::Node[:cbase, *]
                parts = [''] + pack_name(n)
              in ::AST::Node[:const, *]
                parts += pack_name(n)
              in ::AST::Node | nil
                # other child nodes and an absent scope add nothing
              in Symbol | String | Numeric => name
                parts.push name
              end
            end
          end
          parts
        end

        # @param node [Parser::AST::Node, nil]
        # @return [String, nil]
        def infer_literal_node_type node
          return nil unless node.is_a?(AST::Node)
          if %i[str dstr].include?(node.type)
            return '::String'
          elsif node.type == :array
            return '::Array'
          elsif node.type == :nil
            return '::NilClass'
          elsif node.type == :hash
            return '::Hash'
          elsif node.type == :int
            return '::Integer'
          elsif node.type == :float
            return '::Float'
          elsif %i[sym dsym].include?(node.type)
            return '::Symbol'
          elsif node.type == :regexp
            return '::Regexp'
          elsif node.type == :irange
            return '::Range'
          elsif %i[true false].include?(node.type)
            return '::Boolean'
            # @todo Support `nil` keyword in types
            # elsif node.type == :nil
            #   return 'NilClass'
          end
          nil
        end

        # @param node [Parser::AST::Node]
        # @return [Position]
        def get_node_start_position node
          Position.new(node.loc.line, node.loc.column)
        end

        # @param node [Parser::AST::Node]
        # @return [Position]
        def get_node_end_position node
          Position.new(node.loc.last_line, node.loc.last_column)
        end

        # @param node [Parser::AST::Node]
        # @param signature [String]
        #
        # @return [String]
        def drill_signature node, signature
          return signature unless node.is_a?(AST::Node)
          if node in [:const, ::Parser::AST::Node | nil => scope, Symbol => name, *]
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            signature += drill_signature(scope, signature) unless scope.nil?
            signature += '::' unless signature.empty?
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            signature += name.to_s
          elsif node in [:cbase, *]
            signature += '::' unless signature.empty?
          elsif node in [:lvar | :ivar | :cvar, Symbol => name, *]
            signature += '.' unless signature.empty?
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            signature += name.to_s
          elsif node in [:send, ::Parser::AST::Node | nil => receiver, Symbol => name, *]
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            signature += drill_signature(receiver, signature) unless receiver.nil?
            signature += '.' unless signature.empty?
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            signature += name.to_s
          end
          signature
        end

        # Convert a DSL method call argument with directly inferrable simple params.
        # @param node [Parser::AST::Node]
        # @return [String, Integer, Float, Symbol, Parser::AST::Node, Array, Hash, Source::Chain, nil]
        def simple_convert node
          return nil unless Parser.is_ast_node?(node)

          case node.type
          when :const
            unpack_name(node)
          when :str, :dstr, :int, :float, :sym, true, false
            # a dstr converts to its first part, e.g. s(:str, "foo") for "foo\#{bar}"
            # str: String, int: Integer, float: Float, sym: Symbol, dstr: its first part node
            (node in [_, String | Integer | Float | Symbol | ::Parser::AST::Node => value, *]) ? value : nil
          when :array
            simple_convert_array(node)
          when :hash
            simple_convert_hash(node)
          else
            Solargraph::Parser.chain(node)
          end
        end

        # @param node [Parser::AST::Node]
        # @return [Array]
        def simple_convert_array node
          return [] unless Parser.is_ast_node?(node) && node.type == :array
          # s(:array, *elements) - every element is a node
          node.children.compact.map do |child|
            # raises NoMatchingPatternError on a non-node child
            child => ::Parser::AST::Node => c
            simple_convert(c)
          end
        end

        # @param node [Parser::AST::Node]
        # @return [Hash]
        def simple_convert_hash node
          return {} unless Parser.is_ast_node?(node) && node.type == :hash
          result = {}
          # @param pair [Parser::AST::Node]
          node.children.each do |pair|
            # s(:pair, s(:sym, key), value); a kwsplat contributes its operand's name with a nil value
            next unless pair in ::Parser::AST::Node[_, ::Parser::AST::Node => key_node, *rest]

            key = (key_node in [_, key_value, *]) ? key_value : nil
            result[key] = simple_convert((rest in [::Parser::AST::Node => value, *]) ? value : nil)
          end
          result
        end

        # @param node [Parser::AST::Node, nil]
        # @return [Hash{Symbol => Chain}]
        def convert_hash node
          return {} unless Parser.is_ast_node?(node)
          if node in [:kwsplat, ::Parser::AST::Node => splatted, *]
            return convert_hash(splatted)
          end
          if node in [_, ::Parser::AST::Node[:kwsplat, *] => first_child, *]
            return convert_hash(first_child)
          end
          # @sg-ignore Translate to something flow sensitive typing understands
          return {} unless node.type == :hash
          result = {}
          # @sg-ignore Translate to something flow sensitive typing understands
          node.children.each do |pair|
            # s(:pair, s(:sym, key), value)
            pair => [_, ::Parser::AST::Node => key_node, *rest]
            key = (key_node in [_, key_value, *]) ? key_value : nil
            result[key] = Solargraph::Parser.chain((rest in [::Parser::AST::Node => value, *]) ? value : nil)
          end
          result
        end

        NIL_NODE = ::Parser::AST::Node.new(:nil)

        # @param node [Parser::AST::Node]
        #
        # @return [Array<Parser::AST::Node>]
        def const_nodes_from node
          return [] unless Parser.is_ast_node?(node)
          result = []
          if node.type == :const
            result.push node
          else
            node.children.each do |child|
              # children that are not nodes (names, literals, nil) hold no constants
              next unless child in ::Parser::AST::Node => child_node

              result.concat const_nodes_from(child_node)
            end
          end
          result
        end

        # @param node [Parser::AST::Node]
        def splatted_hash? node
          node in [_, ::Parser::AST::Node[:kwsplat, *], *]
        end

        # @param node [Parser::AST::Node]
        def splatted_call? node
          # **splatted as the first child, unless splatted is a hash literal
          return false unless node in ::Parser::AST::Node[_, ::Parser::AST::Node[:kwsplat, ::Parser::AST::Node => splatted, *], *]

          # @sg-ignore https://github.com/castwide/solargraph/pull/1416
          splatted.type != :hash
        end

        # @param nodes [Enumerable<Parser::AST::Node>]
        def any_splatted_call? nodes
          nodes.any? { |n| splatted_call?(n) }
        end

        # Anonymous `*`, `**` and `...` arguments pass on whatever the
        # enclosing method received, so neither count nor types are known.
        #
        # @param nodes [Enumerable<Parser::AST::Node>]
        def any_forwarded_args? nodes
          nodes.any? do |n|
            next false unless Parser.is_ast_node?(n)
            next true if %i[forwarded_args forwarded_restarg].include?(n.type)
            n.type == :hash && n.children.any? { |c| Parser.is_ast_node?(c) && c.type == :forwarded_kwrestarg }
          end
        end

        # @todo Temporarily here for testing. Move to Solargraph::Parser.
        # @param node [Parser::AST::Node]
        # @return [Array<Parser::AST::Node>]
        def call_nodes_from node
          return [] unless node.is_a?(::Parser::AST::Node)
          result = []
          if node in [:block, ::Parser::AST::Node => call, *block_rest]
            result.push node
            if call in ::Parser::AST::Node[_, _, _, *call_args]
              # @sg-ignore Need to add nil check here
              call_args.each { |child| result.concat call_nodes_from(child) }
            end
            # @sg-ignore Need to add nil check here
            block_rest.each { |child| result.concat call_nodes_from(child) }
          elsif node in [:send, ::Parser::AST::Node | nil => receiver, _, *args]
            result.push node
            result.concat call_nodes_from(receiver)
            # @sg-ignore Need to add nil check here
            args.each { |child| result.concat call_nodes_from(child) }
          elsif %i[super zsuper].include?(node.type)
            result.push node
            node.children.each do |child|
              # children that are not nodes (names, literals, nil) hold no calls
              next unless child in ::Parser::AST::Node => child_node

              result.concat call_nodes_from(child_node)
            end
          else
            node.children.each do |child|
              # children that are not nodes (names, literals, nil) hold no calls
              next unless child in ::Parser::AST::Node => child_node

              result.concat call_nodes_from(child_node)
            end
          end
          result
        end

        # Find all the nodes within the provided node that potentially return a
        # value.
        #
        # The node parameter typically represents a method's logic, e.g., the
        # second child (after the :args node) of a :def node. A simple one-line
        # method would typically return itself, while a node with conditions
        # would return the resulting node from each conditional branch. Nodes
        # that follow a :return node are assumed to be unreachable. Nil values
        # are converted to nil node types.
        #
        # @param node [Parser::AST::Node]
        # @return [Array<Parser::AST::Node>]
        def returns_from_method_body node
          # @todo is the || NIL_NODE necessary?
          # STDERR.puts("Evaluating expression: #{node.inspect}")
          DeepInference.from_method_body(node).map { |n| n || NIL_NODE }
        end

        # @param node [Parser::AST::Node]
        # @return [Array<AST::Node>] low-level value nodes in
        #   value position.  Does not include explicit return
        #   statements
        def value_position_nodes_only node
          DeepInference.value_position_nodes_only(node).map { |n| n || NIL_NODE }
        end

        # @param cursor [Solargraph::Source::Cursor]
        # @return [Parser::AST::Node, nil]
        def find_recipient_node cursor
          if cursor.source.repaired? && cursor.source.code[cursor.offset - 1] == '('
            return repaired_find_recipient_node(cursor)
          end
          source = cursor.source
          position = cursor.position
          offset = cursor.offset
          tree = if source.synchronized?
                   # @sg-ignore Need to add nil check here
                   match = source.code[0..(offset - 1)].match(/,\s*\z/)
                   if match
                     # @sg-ignore Need to add nil check here
                     source.tree_at(position.line, position.column - match[0].length)
                   else
                     source.tree_at(position.line, position.column)
                   end
                 else
                   source.tree_at(position.line, position.column - 1)
                 end
          # @type [AST::Node, nil]
          prev = nil
          tree.each do |node|
            if node in [:send, _, _, *args]
              # @sg-ignore Need to add nil check here
              if !args.empty?
                # @sg-ignore Need to add nil check here
                return node if prev && args.include?(prev)
              elsif source.synchronized?
                return node if source.code[0..(offset - 1)] =~ /\(\s*\z/ && source.code[offset..] =~ /^\s*\)/
              elsif source.code[0..(offset - 1)] =~ /\([^(]*\z/
                return node
              end
            end
            prev = node
          end
          find_recipient_node_by_text(source, offset)
        end

        # Text-based fallback for finding a method call recipient when the AST
        # is unavailable (e.g., unparseable source with syntax errors).
        #
        # Scans backward from cursor offset to find '(' and the method name
        # before it, then creates a minimal :send node.
        #
        # @param source [Solargraph::Source]
        # @param offset [Integer]
        # @return [Parser::AST::Node, nil]
        def find_recipient_node_by_text source, offset
          code = source.code
          return nil if offset.nil? || offset <= 0 || offset > code.length

          # The '(' could be at offset-1 (cursor after '(') or at offset (cursor on '(')
          start_pos = offset - 1
          if start_pos.positive? && code[start_pos] != '(' && code[offset] == '('
            start_pos = offset
          end

          # Scan backward to find the matching '(' (handle nested parens)
          depth = 0
          paren_pos = nil
          pos = start_pos
          while pos >= 0
            case code[pos]
            when ')'
              depth += 1
            when '('
              if depth.zero?
                paren_pos = pos
                break
              end
              depth -= 1
            end
            pos -= 1
          end
          return nil if paren_pos.nil?

          # Skip whitespace before '(' to find method name
          idx = paren_pos - 1
          idx -= 1 while idx >= 0 && code[idx] =~ /\s/
          return nil if idx.negative?

          # Read method name (including ? and !)
          name_end = idx + 1
          idx -= 1 while idx >= 0 && code[idx] =~ /[a-zA-Z0-9_?!]/
          name_start = idx + 1
          return nil if name_start >= name_end
          method_name = code[name_start...name_end]
          return nil if method_name.empty?

          # Check for receiver pattern: receiver.method( or receiver::method(
          idx = name_start - 1
          idx -= 1 while idx >= 0 && code[idx] =~ /\s/
          if idx >= 0 && code[idx] == '.'
            idx -= 1
            idx -= 1 while idx >= 0 && code[idx] =~ /\s/
            recv_end = idx + 1
            idx -= 1 while idx >= 0 && code[idx] =~ /[a-zA-Z0-9_@$]/
            recv_start = idx + 1
            if recv_start < recv_end
              recv_name = code[recv_start...recv_end]
              unless recv_name.empty?
                receiver_node = ::Parser::AST::Node.new(:send, [nil, recv_name.to_sym])
                return ::Parser::AST::Node.new(:send, [receiver_node, method_name.to_sym])
              end
            end
          elsif idx >= 0 && idx.positive? && code[idx - 1] == ':' && code[idx] == ':'
            const_end = idx - 1
            const_start = const_end
            const_start -= 1 while const_start.positive? && code[const_start - 1] =~ /[a-zA-Z0-9_]/
            const_name = code[const_start...const_end]
            unless const_name.empty? || method_name.empty?
              const_node = ::Parser::AST::Node.new(:const, [nil, const_name.to_sym])
              return ::Parser::AST::Node.new(:send, [const_node, method_name.to_sym])
            end
          end

          # Simple method call without receiver
          ::Parser::AST::Node.new(:send, [nil, method_name.to_sym])
        end

        # @param cursor [Solargraph::Source::Cursor]
        # @return [Parser::AST::Node, nil]
        def repaired_find_recipient_node cursor
          c = cursor.source.cursor_at([cursor.position.line, cursor.position.column - 1])
          tree = c.source.tree_at(c.position.line, c.position.column)
          tree.each do |node|
            return node if node.type == :send
          end
          find_recipient_node_by_text(cursor.source, cursor.offset)
        end

        #
        # Concepts:
        #
        #  - statement - one single node in the AST.  Generally used
        #    synonymously with how the Parser gem uses the term
        #    'expression'.  This may have side effects (e.g.,
        #    registering a method in the namespace, modifying
        #    variables or doing I/O).  It may encapsulate multiple
        #    other statements (see compound statement).
        #
        #  - value - something that can be assigned to a variable by
        #    evaluating a statement
        #
        #  - value node - the 'lowest level' AST node whose return
        #    type is a subset of the value type of the overall
        #    statement.  Might be a literal, a method call, etc - the
        #    goal is to find the lowest level node, which we can use
        #    Chains and Pins later on to determine the type of.
        #
        #    e.g., if the node 'b ? 123 : 456' were a return value, we
        #    know the actual return values possible are 123 and 456,
        #    and can disregard the rest.
        #
        #  - value type - the type representing the multiple possible
        #    values that can result from evaluation of the statement.
        #
        #  - return type - the type describing the values a statement
        #    might evaluate to.  When used with a method, the term
        #    describes the values that may result from the method
        #    being called, and includes explicit return statements
        #    within the method body's closure.
        #
        #  - method body - a compound statement with parameters whose
        #    return value type must account both for the explicit
        #    'return' statemnts as well as the final statements
        #    executed in any given control flow through the method.
        #
        #  - explicit return statement - a statement which, when part of a
        #     method body, is a possible value of a call to that method -
        #     e.g., "return 123"
        #
        #  - compound statement - a statement which can be expanded to
        #     be multiple statements in a row, executed in the context
        #     of a method which can be explicitly returned from.
        #
        #  - value position - the positions in the AST where the
        #    return type of the statement would be one of the return
        #    types of any compound statements it is a part of.  For a
        #    compound statement, the last of the child statements
        #    would be in return position.  This concept can be applied
        #    recursively through e.g. conditionals to find a list of
        #    statements in value positions.
        module DeepInference
          class << self
            CONDITIONAL_ALL_BUT_FIRST = %i[if unless].freeze
            ONLY_ONE_CHILD = [:return].freeze
            FIRST_TWO_CHILDREN = [:rescue].freeze
            # :ensure's value is always its body's value (first
            # child); the ensure clause itself (second child) never
            # contributes to the method's return value unless it
            # explicitly returns.
            ENSURE = [:ensure].freeze
            COMPOUND_STATEMENTS = %i[begin kwbegin].freeze
            SKIPPABLE = %i[def defs class sclass module].freeze
            FUNCTION_VALUE = [:block].freeze
            CASE_STATEMENT = [:case].freeze

            # @param node [AST::Node] a method body compound statement
            # @return [Array<AST::Node>] low-level value nodes from
            #   both nodes in value position as well as explicit
            #   return statements in the method's closure.
            def from_method_body node
              from_value_position_statement(node, include_explicit_returns: true)
            end

            # @param node [AST::Node] an individual statement, to be
            #   evaluated outside the context of a containing method
            # @return [Array<AST::Node>] low-level value nodes in
            #   value position.  Does not include explicit return
            #   statements
            def value_position_nodes_only node
              from_value_position_statement(node, include_explicit_returns: false)
            end

            # Look at known control statements and use them to find
            # more specific return nodes.
            #
            # @param node [AST::Node] Statement which is in
            #    value position for a method body
            # @param include_explicit_returns [Boolean] If true,
            #    include the value nodes of the parameter of the
            #    'return' statements in the type returned.
            # @return [Array<Parser::AST::Node>]
            def from_value_position_statement node, include_explicit_returns: true
              # STDERR.puts("from_expression called on #{node.inspect}")
              return [] unless node.is_a?(::Parser::AST::Node)
              # @type [Array<Parser::AST::Node>]
              result = []
              if COMPOUND_STATEMENTS.include?(node.type)
                result.concat from_value_position_compound_statement node
              elsif CONDITIONAL_ALL_BUT_FIRST.include?(node.type)
                # s(:if, condition, then, else)
                node => [_, _, *branches]
                result.concat reduce_to_value_nodes(branches)
                # result.push NIL_NODE unless node.children[2]
              elsif ONLY_ONE_CHILD.include?(node.type)
                # s(:return) or s(:return, value, *more_values)
                returned = (node in [_, ::Parser::AST::Node => value, *]) ? value : nil
                result.concat reduce_to_value_nodes([returned])
              elsif FIRST_TWO_CHILDREN.include?(node.type)
                # s(:rescue, body, resbody, *more_resbodies, else)
                node => [_, ::Parser::AST::Node | nil => body, ::Parser::AST::Node => first_resbody, *]
                result.concat reduce_to_value_nodes([body, first_resbody])
              elsif ENSURE.include?(node.type)
                # s(:ensure, body, ensure_body)
                node => [_, ::Parser::AST::Node | nil => ensured_body, *]
                result.concat reduce_to_value_nodes([ensured_body])
                if include_explicit_returns && (node in [_, _, ::Parser::AST::Node => ensure_body, *])
                  result.concat explicit_return_values_from_compound_statement(ensure_body)
                end
              elsif FUNCTION_VALUE.include?(node.type)
                # the block itself is a first class value that could be returned
                result.push node
                # @todo any explicit returns actually return from
                #   scope in which the proc is run.  This asssumes
                #   that the function is executed here.
                # s(:block, call, args, body)
                if include_explicit_returns && (node in [_, _, _, ::Parser::AST::Node => block_body, *])
                  result.concat explicit_return_values_from_compound_statement(block_body)
                end
              elsif CASE_STATEMENT.include?(node.type)
                # s(:case, subject, *whens, else)
                node => [_, _, *clauses]
                # @sg-ignore Need to add nil check here
                clauses.each do |cc|
                  if cc.nil?
                    result.push NIL_NODE
                  elsif cc in [:when, *, ::Parser::AST::Node | nil => when_body]
                    result.concat reduce_to_value_nodes([when_body])
                  else
                    # else clause in case
                    result.concat reduce_to_value_nodes([cc])
                  end
                end
              elsif node in [:resbody, _, _, ::Parser::AST::Node | nil => body, *]
                result.concat reduce_to_value_nodes([body])
              else
                result.push node
              end
              result
            end

            # Treat parent as as a begin block and use the last node's
            # return node plus any explicit return nodes' return nodes.  e.g.,
            #
            #    123
            #    456
            #    return 'a' if foo == bar
            #    789
            #
            #  would return 'a' and 789.
            #
            # @param parent [Parser::AST::Node]
            #
            # @return [Array<Parser::AST::Node>]
            def from_value_position_compound_statement parent
              result = []
              nodes = parent.children.select { |n| n.is_a?(AST::Node) }
              nodes.each_with_index do |child, idx|
                # nodes holds only the node children
                child => ::Parser::AST::Node => node
                if node in [:block, _, _, ::Parser::AST::Node | nil => body, *]
                  result.concat explicit_return_values_from_compound_statement(body) if body
                elsif node in [:rescue, ::Parser::AST::Node | nil => body, ::Parser::AST::Node => first_resbody, *]
                  # body statements
                  result.concat from_value_position_statement(body) if body
                  # rescue statements
                  result.concat from_value_position_statement(first_resbody)
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                elsif SKIPPABLE.include?(node.type)
                  next
                elsif node in [:resbody, _, _, ::Parser::AST::Node | nil => body, *]
                  result.concat reduce_to_value_nodes([body])
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                elsif node.type == :return
                  returned = (node in [_, ::Parser::AST::Node => value, *]) ? value : nil
                  result.concat reduce_to_value_nodes([returned])
                  # Return here because the rest of the code is
                  # unreachable and shouldn't be looked at
                  return result
                else
                  result.concat explicit_return_values_from_compound_statement(node)
                end
                # handle last line of compound statements, which is in
                # value position.  we already have the explicit values
                # from above; now we need to also gather the value
                # position nodes
                if idx == nodes.length - 1
                  result.concat from_value_position_statement(nodes.last,
                                                              include_explicit_returns: false)
                end
              end
              result
            end

            private

            # Useful when this statement isn't in value position, but
            # we care explicit return statements nonetheless.
            #
            # @param parent [Parser::AST::Node]
            #
            # @return [Array<Parser::AST::Node>]
            def explicit_return_values_from_compound_statement parent
              return [] unless parent.is_a?(::Parser::AST::Node)
              result = []
              parent.children.each do |child|
                # names, literals and nil hold no return statements
                next unless child in ::Parser::AST::Node => node
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                next if SKIPPABLE.include?(node.type)
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                if node.type == :return
                  returned = (node in [_, ::Parser::AST::Node => value, *]) ? value : nil
                  result.concat reduce_to_value_nodes([returned])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat explicit_return_values_from_compound_statement(node)
                end
              end
              result
            end

            # @param nodes [Enumerable<Parser::AST::Node, BasicObject>]
            # @return [Array<Parser::AST::Node, nil>]
            def reduce_to_value_nodes nodes
              result = []
              nodes.each do |node|
                if !node.is_a?(::Parser::AST::Node)
                  result.push nil
                # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
                elsif COMPOUND_STATEMENTS.include?(node.type)
                  result.concat from_value_position_compound_statement(node)
                # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
                elsif CONDITIONAL_ALL_BUT_FIRST.include?(node.type)
                  node => [_, _, *branches]
                  result.concat reduce_to_value_nodes(branches)
                elsif node.type == :return
                  # s(:return, value, *more_values)
                  first = (node in [_, ::Parser::AST::Node => value, *]) ? value : nil
                  result.concat reduce_to_value_nodes([first])
                elsif FIRST_TWO_CHILDREN.include?(node.type)
                  # a :rescue node's value is its body's value or the
                  # value of whichever resbody handled the exception
                  node => [_, ::Parser::AST::Node | nil => body, ::Parser::AST::Node => first_resbody, *]
                  result.concat reduce_to_value_nodes([body, first_resbody])
                # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
                elsif node.type == :block
                  body = (node in [_, _, _, ::Parser::AST::Node | nil => block_body, *]) ? block_body : nil
                  result.concat explicit_return_values_from_compound_statement(body) unless body.nil?
                # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
                elsif node.type == :resbody
                  body = (node in [_, _, _, ::Parser::AST::Node | nil => resbody_body, *]) ? resbody_body : nil
                  result.concat reduce_to_value_nodes([body])
                else
                  result.push node
                end
              end
              result
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
