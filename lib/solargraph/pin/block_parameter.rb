module Solargraph
  module Pin
    class BlockParameter < Base
      include Localized

      # @return [Pin::Block]
      attr_reader :block

      def initialize location, namespace, name, comments, block
        super(location, namespace, name, comments)
        @block = block
        @presence = block.location.range
      end

      # @return [Integer]
      def kind
        Pin::BLOCK_PARAMETER
      end

      # @return [Integer]
      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      # The parameter's zero-based location in the block's signature.
      #
      # @return [Integer]
      def index
        block.parameters.index(self)
      end

      def nearly? other
        return false unless super
        block.nearly?(other.block)
      end

      def try_merge! other
        return false unless super
        @block = other.block
        @presence = other.block.location.range
        @return_complex_type = nil
        true
      end

      # @return [Array<Solargraph::ComplexType>]
      def return_complex_type
        if @return_complex_type.nil?
          @return_complex_type = ComplexType.new
          found = nil
          params = block.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
            break
          end
          if found.nil? and !index.nil?
            found = params[index] if params[index] && (params[index].name.nil? || params[index].name.empty?)
          end
          @return_complex_type = ComplexType.try_parse(*found.types) unless found.nil? or found.types.nil?
        end
        super
        @return_complex_type
      end

      def context
        block
      end

      # @param api_map [ApiMap]
      def typify api_map
        # @todo Does anything need to be eliminated because it's more accurately a probe?
        type = super
        return type unless type.undefined?
        chain = Source::NodeChainer.chain(block.receiver, filename)
        clip = api_map.clip_at(location.filename, location.range.start)
        locals = clip.locals - [self]
        meths = chain.define(api_map, block, locals)
        meths.each do |meth|
          if (Solargraph::CoreFills::METHODS_WITH_YIELDPARAM_SUBTYPES.include?(meth.path))
            bmeth = chain.base.define(api_map, context, locals).first
            return ComplexType::UNDEFINED if bmeth.nil? or bmeth.return_complex_type.undefined? or bmeth.return_complex_type.subtypes.empty?
            return bmeth.return_complex_type.subtypes.first.qualify(api_map, bmeth.context.namespace)
          else
            yps = meth.docstring.tags(:yieldparam)
            unless yps[index].nil? or yps[index].types.nil? or yps[index].types.empty?
              return ComplexType.try_parse(yps[index].types.first).qualify(api_map, meth.context.namespace)
            end
          end
        end
        ComplexType::UNDEFINED
      end
    end
  end
end
