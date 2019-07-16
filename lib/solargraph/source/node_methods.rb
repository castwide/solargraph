# frozen_string_literal: true

module Solargraph
  class Source
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
      # @return [String]
      def const_from node
        if node.is_a?(AST::Node) and node.type == :const
          result = ''
          unless node.children[0].nil?
            result = const_from(node.children[0])
          end
          if result == ''
            result = node.children[1].to_s
          else
            result = result + '::' + node.children[1].to_s
          end
          result
        else
          nil
        end
      end

      # @param node [Parser::AST::Node]
      # @return [String]
      def infer_literal_node_type node
        return nil unless node.is_a?(AST::Node)
        if node.type == :str || node.type == :dstr
          return 'String'
        elsif node.type == :array
          return 'Array'
        elsif node.type == :hash
          return 'Hash'
        elsif node.type == :int
          return 'Integer'
        elsif node.type == :float
          return 'Float'
        elsif node.type == :sym
          return 'Symbol'
        elsif node.type == :regexp
          return 'Regexp'
        elsif node.type == :irange
          return 'Range'
        # @todo Support `nil` keyword in types
        # elsif node.type == :nil
        #   return 'NilClass'
        end
        nil
      end

      # Get a call signature from a node.
      # The result should be a string in the form of a method path, e.g.,
      # String.new or variable.method.
      #
      # @param node [Parser::AST::Node]
      # @return [String]
      def resolve_node_signature node
        result = drill_signature node, ''
        return nil if result.empty?
        result
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

      # Find all the nodes within the provided node that potentially return a
      # value.
      #
      # The node parameter typically represents a method's logic, e.g., the
      # second child (after the :args node) of a :def node. A simple one-line
      # method would typically return itself, while a node with conditions
      # would return the resulting node from each conditional branch. Nodes
      # that follow a :return node are assumed to be unreachable. Implicit nil
      # values are ignored.
      #
      # @todo Maybe this method should include implicit nil values in results.
      #   For example, a bare `return` would return a :nil node instead of an
      #   empty array.
      #
      # @param node [Parser::AST::Node]
      # @return [Array<Parser::AST::Node>]
      def returns_from node
        DeepInference.get_return_nodes(node)
      end

      module DeepInference
        class << self
          CONDITIONAL = [:if, :unless]
          REDUCEABLE = [:begin, :kwbegin]
          SKIPPABLE = [:def, :defs, :class, :sclass, :module, :block]

          # @param node [Parser::AST::Node]
          # @return [Array<Parser::AST::Node>]
          def get_return_nodes node
            return [] unless node.is_a?(Parser::AST::Node)
            result = []
            if REDUCEABLE.include?(node.type)
              result.concat get_return_nodes_from_children(node)
            elsif CONDITIONAL.include?(node.type)
              result.concat reduce_to_value_nodes(node.children[1..-1])
            elsif node.type == :and || node.type == :or
              result.concat reduce_to_value_nodes(node.children)
            elsif node.type == :return
              result.concat reduce_to_value_nodes([node.children[0]])
            elsif node.type == :block
              result.concat reduce_to_value_nodes(node.children[0..-2])
            else
              result.push node
            end
            result
          end

          private

          def get_return_nodes_from_children parent
            result = []
            nodes = parent.children.select{|n| n.is_a?(AST::Node)}
            nodes[0..-2].each do |node|
              next if SKIPPABLE.include?(node.type)
              if node.type == :return
                result.concat reduce_to_value_nodes([node.children[0]])
                # Return the result here because the rest of the code is
                # unreachable
                return result
              else
                result.concat get_return_nodes_only(node)
              end
            end
            result.concat reduce_to_value_nodes([nodes.last]) unless nodes.last.nil?
            result
          end

          def get_return_nodes_only parent
            return [] unless parent.is_a?(Parser::AST::Node)
            result = []
            nodes = parent.children.select{|n| n.is_a?(Parser::AST::Node)}
            nodes.each do |node|
              next if SKIPPABLE.include?(node.type)
              if node.type == :return
                result.concat reduce_to_value_nodes([node.children[0]])
                # Return the result here because the rest of the code is
                # unreachable
                return result
              else
                result.concat get_return_nodes_only(node)
              end
            end
            result
          end

          def reduce_to_value_nodes nodes
            result = []
            nodes.each do |node|
              if !node.is_a?(Parser::AST::Node)
                result.push nil
              elsif REDUCEABLE.include?(node.type)
                result.concat get_return_nodes_from_children(node)
              elsif CONDITIONAL.include?(node.type)
                result.concat reduce_to_value_nodes(node.children[1..-1])
              elsif node.type == :return
                result.concat get_return_nodes(node.children[0])
              elsif node.type == :and || node.type == :or
                result.concat reduce_to_value_nodes(node.children)
              elsif node.type == :block
                result.concat get_return_nodes_only(node.children[2])
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
