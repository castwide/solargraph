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

    def const_from node
      if node.kind_of?(AST::Node) and node.type == :const
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

    def infer_literal_node_type node
      return nil unless node.kind_of?(AST::Node)
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
      end
      nil
    end

    # Get a call signature from a node.
    # The result should be a string in the form of a method path, e.g.,
    # String.new or variable.method.
    #
    # @return [String]
    def resolve_node_signature node
      drill_signature node, ''
    end

    private

    def drill_signature node, signature
      return signature unless node.kind_of?(AST::Node)
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
  end
end
