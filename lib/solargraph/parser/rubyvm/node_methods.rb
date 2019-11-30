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
      end
    end
  end
end
