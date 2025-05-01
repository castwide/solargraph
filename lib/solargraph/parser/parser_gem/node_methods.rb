# frozen_string_literal: true

require 'parser'
require 'ast'

# Teach AST::Node#children about its generic type
#
# @todo contribute back to https://github.com/ruby/gem_rbs_collection/blob/main/gems/ast/2.4/ast.rbs
#
# @!parse
#   module ::AST
#     class Node
#       # New children
#
#       # @return [Array<self>]
#       attr_reader :children
#     end
#   end

# https://github.com/whitequark/parser
module Solargraph
  module Parser
    module ParserGem
      module NodeMethods
        module_function

        # @param node [Parser::AST::Node]
        # @return [String]
        def unpack_name(node)
          pack_name(node).join("::")
        end

        # @param node [Parser::AST::Node]
        # @return [Array<String>]
        def pack_name(node)
          # @type [Array<String>]
          parts = []
          if node.is_a?(AST::Node)
            node.children.each { |n|
              if n.is_a?(AST::Node)
                if n.type == :cbase
                  parts = [''] + pack_name(n)
                else
                  parts += pack_name(n)
                end
              else
                parts.push n unless n.nil?
              end
            }
          end
          parts
        end

        # @param node [Parser::AST::Node]
        # @return [String, nil]
        def infer_literal_node_type node
          return nil unless node.is_a?(AST::Node)
          if node.type == :str || node.type == :dstr
            return '::String'
          elsif node.type == :array
            return '::Array'
          elsif node.type == :hash
            return '::Hash'
          elsif node.type == :int
            return '::Integer'
          elsif node.type == :float
            return '::Float'
          elsif node.type == :sym || node.type == :dsym
            return '::Symbol'
          elsif node.type == :regexp
            return '::Regexp'
          elsif node.type == :irange
            return '::Range'
          elsif node.type == :true || node.type == :false
            return '::Boolean'
            # @todo Support `nil` keyword in types
          # elsif node.type == :nil
          #   return 'NilClass'
          end
          nil
        end

        # @param node [Parser::AST::Node]
        # @return [Position]
        def get_node_start_position(node)
          Position.new(node.loc.line, node.loc.column)
        end

        # @param node [Parser::AST::Node]
        # @return [Position]
        def get_node_end_position(node)
          Position.new(node.loc.last_line, node.loc.last_column)
        end

        # @param node [Parser::AST::Node]
        # @param signature [String]
        #
        # @return [String]
        def drill_signature node, signature
          return signature unless node.is_a?(AST::Node)
          if node.type == :const or node.type == :cbase
            unless node.children[0].nil?
              signature += drill_signature(node.children[0], signature)
            end
            signature += '::' unless signature.empty?
            signature += node.children[1].to_s
          elsif node.type == :lvar or node.type == :ivar or node.type == :cvar
            signature += '.' unless signature.empty?
            signature += node.children[0].to_s
          elsif node.type == :send
            unless node.children[0].nil?
              signature += drill_signature(node.children[0], signature)
            end
            signature += '.' unless signature.empty?
            signature += node.children[1].to_s
          end
          signature
        end

        # @param node [Parser::AST::Node]
        # @return [Hash{Parser::AST::Node => Chain}]
        def convert_hash node
          return {} unless Parser.is_ast_node?(node)
          return convert_hash(node.children[0]) if node.type == :kwsplat
          return convert_hash(node.children[0]) if Parser.is_ast_node?(node.children[0]) && node.children[0].type == :kwsplat
          return {} unless node.type == :hash
          result = {}
          node.children.each do |pair|
            result[pair.children[0].children[0]] = Solargraph::Parser.chain(pair.children[1])
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
            node.children.each { |child| result.concat const_nodes_from(child) }
          end
          result
        end

        # @param node [Parser::AST::Node]
        def splatted_hash? node
          Parser.is_ast_node?(node.children[0]) && node.children[0].type == :kwsplat
        end

        # @param node [Parser::AST::Node]
        def splatted_call? node
          return false unless Parser.is_ast_node?(node)
          Parser.is_ast_node?(node.children[0]) && node.children[0].type == :kwsplat && node.children[0].children[0].type != :hash
        end

        # @param nodes [Enumerable<Parser::AST::Node>]
        def any_splatted_call?(nodes)
          nodes.any? { |n| splatted_call?(n) }
        end

        # @todo Temporarily here for testing. Move to Solargraph::Parser.
        # @param node [Parser::AST::Node]
        # @return [Array<Parser::AST::Node>]
        def call_nodes_from node
          return [] unless node.is_a?(::Parser::AST::Node)
          result = []
          if node.type == :block
            result.push node
            if Parser.is_ast_node?(node.children[0]) && node.children[0].children.length > 2
              node.children[0].children[2..-1].each { |child| result.concat call_nodes_from(child) }
            end
            node.children[1..-1].each { |child| result.concat call_nodes_from(child) }
          elsif node.type == :send
            result.push node
            node.children[2..-1].each { |child| result.concat call_nodes_from(child) }
          elsif [:super, :zsuper].include?(node.type)
            result.push node
            node.children.each { |child| result.concat call_nodes_from(child) }
          else
            node.children.each { |child| result.concat call_nodes_from(child) }
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
        def value_position_nodes_only(node)
          DeepInference.value_position_nodes_only(node).map { |n| n || NIL_NODE }
        end

        # @param cursor [Solargraph::Source::Cursor]
        # @return [Parser::AST::Node, nil]
        def find_recipient_node cursor
          return repaired_find_recipient_node(cursor) if cursor.source.repaired? && cursor.source.code[cursor.offset - 1] == '('
          source = cursor.source
          position = cursor.position
          offset = cursor.offset
          tree = if source.synchronized?
            match = source.code[0..offset-1].match(/,\s*\z/)
            if match
              source.tree_at(position.line, position.column - match[0].length)
            else
              source.tree_at(position.line, position.column)
            end
          else
            source.tree_at(position.line, position.column - 1)
          end
          prev = nil
          tree.each do |node|
            if node.type == :send
              args = node.children[2..-1]
              if !args.empty?
                return node if prev && args.include?(prev)
              else
                if source.synchronized?
                  return node if source.code[0..offset-1] =~ /\(\s*\z/ && source.code[offset..-1] =~ /^\s*\)/
                else
                  return node if source.code[0..offset-1] =~ /\([^\(]*\z/
                end
              end
            end
            prev = node
          end
          nil
        end

        # @param cursor [Solargraph::Source::Cursor]
        # @return [Parser::AST::Node, nil]
        def repaired_find_recipient_node cursor
          cursor = cursor.source.cursor_at([cursor.position.line, cursor.position.column - 1])
          node = cursor.source.tree_at(cursor.position.line, cursor.position.column).first
          return node if node && node.type == :send
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
            CONDITIONAL_ALL_BUT_FIRST = [:if, :unless]
            CONDITIONAL_ALL = [:or]
            ONLY_ONE_CHILD = [:return]
            FIRST_TWO_CHILDREN = [:rescue]
            COMPOUND_STATEMENTS = [:begin, :kwbegin]
            SKIPPABLE = [:def, :defs, :class, :sclass, :module]
            FUNCTION_VALUE = [:block]
            CASE_STATEMENT = [:case]

            # @param node [AST::Node] a method body compound statement
            # @param include_explicit_returns [Boolean] If true,
            #    include the value nodes of the parameter of the
            #    'return' statements in the type returned.
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
            def value_position_nodes_only(node)
              from_value_position_statement(node, include_explicit_returns: false)
            end

            # Look at known control statements and use them to find
            # more specific return nodes.
            #
            # @param node [Parser::AST::Node] Statement which is in
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
                result.concat reduce_to_value_nodes(node.children[1..-1])
                # result.push NIL_NODE unless node.children[2]
              elsif CONDITIONAL_ALL.include?(node.type)
                result.concat reduce_to_value_nodes(node.children)
              elsif ONLY_ONE_CHILD.include?(node.type)
                result.concat reduce_to_value_nodes([node.children[0]])
              elsif FIRST_TWO_CHILDREN.include?(node.type)
                result.concat reduce_to_value_nodes([node.children[0], node.children[1]])
              elsif FUNCTION_VALUE.include?(node.type)
                # the block itself is a first class value that could be returned
                result.push node
                # @todo any explicit returns actually return from
                #   scope in which the proc is run.  This asssumes
                #   that the function is executed here.
                result.concat explicit_return_values_from_compound_statement(node.children[2]) if include_explicit_returns
              elsif CASE_STATEMENT.include?(node.type)
                node.children[1..-1].each do |cc|
                  if cc.nil?
                    result.push NIL_NODE
                  elsif cc.type == :when
                    result.concat reduce_to_value_nodes([cc.children.last])
                  else
                    # else clause in case
                    result.concat reduce_to_value_nodes([cc])
                  end
                end
              elsif node.type == :resbody
                result.concat reduce_to_value_nodes([node.children[2]])
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
              nodes = parent.children.select{|n| n.is_a?(AST::Node)}
              nodes.each_with_index do |node, idx|
                if node.type == :block
                  result.concat explicit_return_values_from_compound_statement(node.children[2])
                elsif node.type == :rescue
                  # body statements
                  result.concat from_value_position_statement(node.children[0])
                  # rescue statements
                  result.concat from_value_position_statement(node.children[1])
                elsif SKIPPABLE.include?(node.type)
                  next
                elsif node.type == :resbody
                  result.concat reduce_to_value_nodes([node.children[2]])
                elsif node.type == :return
                  result.concat reduce_to_value_nodes([node.children[0]])
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
                result.concat from_value_position_statement(nodes.last, include_explicit_returns: false) if idx == nodes.length - 1
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
              nodes = parent.children.select{|n| n.is_a?(::Parser::AST::Node)}
              nodes.each do |node|
                next if SKIPPABLE.include?(node.type)
                if node.type == :return
                  result.concat reduce_to_value_nodes([node.children[0]])
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
                elsif COMPOUND_STATEMENTS.include?(node.type)
                  result.concat from_value_position_compound_statement(node)
                elsif CONDITIONAL_ALL_BUT_FIRST.include?(node.type)
                  result.concat reduce_to_value_nodes(node.children[1..-1])
                elsif node.type == :return
                  result.concat reduce_to_value_nodes([node.children[0]])
                elsif node.type == :or
                  result.concat reduce_to_value_nodes(node.children)
                elsif node.type == :block
                  result.concat explicit_return_values_from_compound_statement(node.children[2])
                elsif node.type == :resbody
                  result.concat reduce_to_value_nodes([node.children[2]])
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
