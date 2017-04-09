module Solargraph
  module NodeMethods
    def unpack_name(node)
      pack_name(node).join("::")
    end
    
    def pack_name(node)
      parts = []
      if node.kind_of?(AST::Node)
        node.children.each { |n|
          if n.kind_of?(AST::Node)
            if n.type == :cbase
              parts = pack_name(n)
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

    def infer node
      if node.type == :str
        return 'String'
      elsif node.type == :array
        return 'Array'
      elsif node.type == :hash
        return 'Hash'
      elsif node.type == :int
        return 'Integer'
      elsif node.type == :float
        return 'Float'
      elsif node.type == :send
        if node.children[0].nil?
          # TODO Another local variable or method or something? sheesh
        else
          ns = unpack_name(node.children[0])
          if node.children[1] == :new
            return ns
          end
        end
      elsif node.type == :cbase or node.type == :const
        unpack_name node
      end
    end

    # Get a call signature from a node.
    # The result should be a string in the form of a method path, e.g.,
    # String.new or variable.method.
    #
    # @return [String]
    def resolve_node_signature node
      stack_node_signature(node).join('.')
    end

    def stack_node_signature node
      parts = []
      if node.kind_of?(AST::Node)
        if node.type == :send
          unless node.children[0].nil?
            parts = [unpack_name(node.children[0])] + parts
          end
          parts += stack_node_signature(node.children[1])
        else
          parts = [unpack_name(node)] + stack_node_signature(node.children[1])
        end
      else
        parts.push node.to_s
      end
      parts
    end
  end
end
