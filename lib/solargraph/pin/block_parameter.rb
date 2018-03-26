module Solargraph
  module Pin
    class BlockParameter < LocalVariable
      def initialize source, node, namespace, ancestors
        super
        # @todo This needs to different from method parameters. It'll be tricky...
        @ancestors = ancestors
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

      def yielding_signature
        resolve_node_signature(@tree[0].children[0])
      end
    end
  end
end
