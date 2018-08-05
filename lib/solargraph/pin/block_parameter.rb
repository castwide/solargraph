module Solargraph
  module Pin
    class BlockParameter < Base
      include Localized

      # @return [Pin::Block]
      attr_reader :block

      def initialize location, namespace, name, docstring, block
        super(location, namespace, name, docstring)
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

      # @return [Array<Solargraph::ComplexType>]
      def return_complex_types
        if @return_complex_types.nil?
          @return_complex_types = []
          unless block.docstring.nil?
            found = nil
            params = block.docstring.tags(:param)
            params.each do |p|
              next unless p.name == name
              found = p
            end
            @return_complex_types.concat ComplexType.parse(*found.types) unless found.nil? or found.types.nil?
          end
        end
        @return_complex_types
      end
    end
  end
end
