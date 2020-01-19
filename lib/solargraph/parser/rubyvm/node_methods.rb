module Solargraph
  module Parser
    module Rubyvm
      module NodeMethods
        # @param node [Parser::AST::Node]
        # @return [String]
        def unpack_name(node)
          pack_name(node).join("::")
        end

        # @param node [Parser::AST::Node]
        # @return [Array<String>]
        def pack_name(node)
          parts = []
          # if node.is_a?(AST::Node)
          if Parser.is_ast_node?(node)
            node.children.each { |n|
              if Parser.is_ast_node?(n)
                if n.type == :COLON2
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

        def infer_literal_node_type node
          return nil unless Parser.is_ast_node?(node)
          case node.type
          when :LIT, :STR
            "::#{node.children.first.class.to_s}"
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
      end
    end
  end
end
