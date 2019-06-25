# frozen_string_literal: true

module Solargraph
  module Pin
    class Attribute < BaseMethod
      # @return [::Symbol] :reader or :writer
      attr_reader :access

      # @param access [::Symbol] :reader or :writer
      def initialize access: :reader, **splat
        super(splat)
        @access = access
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end

      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::PROPERTY
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def probe api_map
        types = []
        varname = "@#{name.gsub(/=$/, '')}"
        pins = api_map.get_instance_variable_pins(binder.namespace, binder.scope).select { |iv| iv.name == varname }
        pins.each do |pin|
          type = pin.typify(api_map)
          type = pin.probe(api_map) if type.undefined?
          types.push type if type.defined?
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.try_parse(*types.map(&:tag).uniq)
      end
    end
  end
end
