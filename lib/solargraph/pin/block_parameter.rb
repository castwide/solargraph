module Solargraph
  module Pin
    class BlockParameter < Base
      include Localized

      attr_reader :index

      attr_reader :block

      def initialize location, namespace, name, docstring, block
        super(location, namespace, name, docstring)
        @block = block
        @presence = block.location.range
      end

      def kind
        Pin::BLOCK_PARAMETER
      end

      def index
        block.parameters.index(self)
      end

      def return_type
        if @return_type.nil? and !block.docstring.nil?
          found = nil
          params = block.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
          end
          @return_type = found.types[0] unless found.nil? or found.types.nil?
        end
        @return_type
      end

      # @param api_map [Solargraph::ApiMap]
      def resolve api_map
        return unless return_type.nil?
        # signature = resolve_node_signature(@tree[0].children[0])
        signature = block.receiver
        # @todo Hardcoding :class scope might not be appropriate
        # meth = api_map.infer_pin(signature, namespace, :class, [:public, :private, :protected], true)
        # meth = api_map.tail_pin(signature, namespace, :class, [:public, :private, :protected])
        meth = api_map.probe.infer_signature_pin(signature, block, [])
        return nil if meth.nil?
        if (Solargraph::CoreFills::METHODS_WITH_YIELDPARAM_SUBTYPES.include?(meth.path))
          base = signature.split('.')[0..-2].join('.')
          return nil if base.nil? or base.empty?
          # @todo Maybe use a fragment so this picks up local variables
          bmeth = nil
          # @todo tail_pin is deprecated
          # bmeth = api_map.tail_pin(base, namespace, :class, [:public, :private, :protected])
          bmeth = api_map.probe.infer_signature_pin(base, block, [])
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
