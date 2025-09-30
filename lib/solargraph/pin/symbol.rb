# frozen_string_literal: true

module Solargraph
  module Pin
    class Symbol < Base
      # @param location [Solargraph::Location]
      # @param name [String]
      # @param [Hash{Symbol => Object}] kwargs
      def initialize(location, name, **kwargs)
        # @sg-ignore "Unrecognized keyword argument kwargs to Solargraph::Pin::Base#initialize"
        super(location: location, name: name, **kwargs)
        # @name = name
        # @location = location
      end

      def namespace
        ''
      end

      def path
        ''
      end

      def closure
        @closure ||= Pin::ROOT_PIN
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def comments
        ''
      end

      def return_type
        @return_type ||= Solargraph::ComplexType::SYMBOL
      end

      def directives
        []
      end

      # @return [::Symbol]
      def visibility
        :public
      end

      def deprecated?
        false
      end
    end
  end
end
