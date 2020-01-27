module Solargraph
  module Parser
    module Rubyvm
      module NodeMethods
        module_function

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [String]
        def unpack_name node
          pack_name(node).join('::')
        end

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [Array<String>]
        def pack_name(node)
          parts = []
          if node.is_a?(RubyVM::AbstractSyntaxTree::Node)
            parts.push '' if node.type == :COLON3
            node.children.each { |n|
              if n.is_a?(RubyVM::AbstractSyntaxTree::Node)
                parts += pack_name(n)
              else
                parts.push n unless n.nil?
              end
            }
          end
          parts
        end

        # @param node [RubyVM::AbstractSyntaxTree::Node]
        # @return [String, nil]
        def infer_literal_node_type node
          return nil unless Parser.is_ast_node?(node)
          case node.type
          when :LIT, :STR
            "::#{node.children.first.class.to_s}"
          when :DSTR
            "::String"
          when :ARRAY, :ZARRAY, :LIST, :ZLIST
            '::Array'
          when :HASH
            '::Hash'
          when :DOT2
            '::Range'
          when :TRUE, :FALSE
            '::Boolean'
          when :SCOPE
            infer_literal_node_type(node.children[2])
          end
        end

        def returns_from node
          return [] unless Parser.is_ast_node?(node)
          if node.type == :SCOPE
            # node.children.select { |n| n.is_a?(RubyVM::AbstractSyntaxTree::Node) }.map { |n| DeepInference.get_return_nodes(n) }.flatten
            DeepInference.get_return_nodes(node.children[2])
          else
            DeepInference.get_return_nodes(node)
          end
        end

        def convert_hash node
          return {} unless node?(node) && node.type == :HASH
          result = {}
          index = 0
          until index > node.children[0].children.length - 2
            k = node.children[0].children[index]
            v = node.children[0].children[index + 1]
            result[k.children[0]] = Solargraph::Parser.chain(v)
            index += 2
          end
          result
        end

        def node? node
          node.is_a?(RubyVM::AbstractSyntaxTree::Node)
        end

        module DeepInference
          class << self
            CONDITIONAL = [:IF, :UNLESS]
            REDUCEABLE = [:BLOCK]
            SKIPPABLE = [:DEFN, :DEFS, :CLASS, :SCLASS, :MODULE]

            # @param node [Parser::AST::Node]
            # @return [Array<Parser::AST::Node>]
            def get_return_nodes node
              return [] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              if REDUCEABLE.include?(node.type)
                result.concat get_return_nodes_from_children(node)
              elsif CONDITIONAL.include?(node.type)
                result.concat reduce_to_value_nodes(node.children[1..-1])
              elsif node.type == :AND || node.type == :OR
                result.concat reduce_to_value_nodes(node.children)
              elsif node.type == :RETURN
                result.concat reduce_to_value_nodes([node.children[0]])
              elsif node.type == :ITER
                result.push node
                result.concat get_return_nodes_only(node.children[1])
              else
                result.push node
              end
              result
            end

            private

            def get_return_nodes_from_children parent
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each_with_index do |node, idx|
                if node.type == :BLOCK
                  result.concat get_return_nodes_only(node.children[2])
                elsif SKIPPABLE.include?(node.type)
                  next
                elsif CONDITIONAL.include?(node.type)
                  result.concat get_return_nodes_only(node)
                elsif node.type == :RETURN
                  result.concat reduce_to_value_nodes([node.children[0]])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat get_return_nodes_only(node)
                end
                result.concat reduce_to_value_nodes([nodes.last]) if idx == nodes.length - 1
              end
              result
            end

            def get_return_nodes_only parent
              return [] unless parent.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each do |node|
                next if SKIPPABLE.include?(node.type)
                if node.type == :RETURN
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
                if !node.is_a?(RubyVM::AbstractSyntaxTree::Node)
                  result.push nil
                elsif REDUCEABLE.include?(node.type)
                  result.concat get_return_nodes_from_children(node)
                elsif CONDITIONAL.include?(node.type)
                  result.concat reduce_to_value_nodes(node.children[1..-1])
                elsif node.type == :RETURN
                  if node.children[0].nil?
                    result.push nil
                  else
                    result.concat get_return_nodes(node.children[0])
                  end
                elsif node.type == :AND || node.type == :OR
                  result.concat reduce_to_value_nodes(node.children)
                elsif node.type == :BLOCK
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
end
