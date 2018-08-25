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
    end
  end
end
