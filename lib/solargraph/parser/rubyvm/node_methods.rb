module Solargraph
  module Parser
    module Rubyvm
      module NodeMethods
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
          when :ARRAY, :ZARRAY
            '::Array'
          when :HASH
            '::Hash'
          when :DOT2
            '::Range'
          when :TRUE, :FALSE
            '::Boolean'
          end
        end
      end
    end
  end
end
