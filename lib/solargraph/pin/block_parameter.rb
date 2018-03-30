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
        meth = api_map.infer_signature_pins(signature, namespace, :class, node).first
        return nil if meth.nil?
        if (Solargraph::CoreFills::METHODS_WITH_YIELDPARAM_SUBTYPES.include?(meth.path))
          base = signature.split('.')[0..-2].join('.')
          return nil if base.nil? or base.empty?
          bmeth = api_map.infer_signature_pins(base, namespace, :class, node).first
          return nil if bmeth.nil?
          subtypes = get_subtypes(bmeth.return_type)
          @return_type = api_map.find_fully_qualified_namespace(subtypes[0], namespace)
        else
          unless meth.docstring.nil?
            yps = meth.docstring.tags(:yieldparam)
            unless yps[index].nil? or yps[index].types.nil? or yps[index].types.empty?
              @return_type = yps[index].types[0]
            end
          end
        end
      end

      private

      def get_subtypes type
        return nil if type.nil?
        match = type.match(/<([a-z0-9_:, ]*)>/i)
        return [] if match.nil?
        match[1].split(',').map(&:strip)
      end        
    end
  end
end
