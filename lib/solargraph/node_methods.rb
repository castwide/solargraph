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
  end
end
