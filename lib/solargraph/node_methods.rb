module Solargraph
  module NodeMethods
    def unpack_name(node)
      pack_name(node).join("::")
    end
    
    def pack_name(node)
      parts = []
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
      parts
    end

    def infer node
      if node.type == :str
        return 'String'
      elsif node.type == :array
        return 'Array'
      elsif node.type == :hash
        return 'Hash'
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
  end
end
