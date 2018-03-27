module Solargraph
  module Pin
    class BlockParameter < LocalVariable
      attr_reader :index

      def initialize source, node, namespace, ancestors, index
        super(source, node, namespace, ancestors)
        @index = index
        docstring = source.docstring_for(ancestors.first)
        unless docstring.nil?
          tags = docstring.tags(:param)
          tags.each do |tag|
            if tag.name == name and !tag.types.nil? and !tag.types.empty?
              @return_type = tag.types[0]
            end
          end
        end
      end

      # @param api_map [Solargraph::ApiMap]
      def resolve api_map
        return unless return_type.nil?
        signature = resolve_node_signature(@tree[0].children[0])
        parts = signature.split('.')
        word = parts.pop
        base = parts.join('.')
        type = api_map.infer_signature_type(base, namespace, scope: :class, call_node: node)
        unless type.nil?
          meth = api_map.get_type_methods(type).select{|pin| pin.name == word}.first
          unless meth.nil? or meth.docstring.nil?
            yps = meth.docstring.tags(:yieldparam)
            unless yps[index].nil? or yps[index].types.nil? or yps[index].types.empty?
              @return_type = yps[index].types[0]
              STDERR.puts "Resolved it! #{@return_type}"
            else
              STDERR.puts "Failed to resolve #{name}, wtf"
            end
          end
        end
      end
    end
  end
end
