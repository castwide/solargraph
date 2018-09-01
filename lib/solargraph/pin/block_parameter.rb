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
        @presence = block.location.range
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
          end
          @return_complex_type = ComplexType.parse(*found.types) unless found.nil? or found.types.nil?
        end
        @return_complex_type
      end

      def context
        block
      end

      def infer api_map
        return return_complex_type unless return_complex_type.undefined?
        chain = SourceMap::NodeChainer.chain(location.filename, block.receiver)
        fragment = api_map.fragment_at(location)
        locals = fragment.locals - [self]
        meths = chain.define_with(api_map, block, fragment.locals)
        meths.each do |meth|
          if (Solargraph::CoreFills::METHODS_WITH_YIELDPARAM_SUBTYPES.include?(meth.path))
            bmeth = chain.define_base_with(api_map, context, locals).first
            return ComplexType::UNDEFINED if bmeth.nil? or bmeth.return_complex_type.undefined? or bmeth.return_complex_type.subtypes.empty?
            return bmeth.return_complex_type.subtypes.first.qualify(api_map)
          else
            yps = meth.docstring.tags(:yieldparam)
            unless yps[index].nil? or yps[index].types.nil? or yps[index].types.empty?
              return ComplexType.parse(yps[index].types[0]).first
            end
          end
        end
        ComplexType::UNDEFINED
      end
    end
  end
end
