module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Source::NodeMethods

      attr_reader :assignment

      def initialize assignment: nil, **splat
        super(splat)
        @assignment = assignment
      end

      def signature
        @signature ||= resolve_node_signature(@assignment)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type.nil?
      end

      def variable?
        true
      end

      def probe api_map
        return ComplexType::UNDEFINED if @assignment.nil?
        types = []
        returns_from(@assignment).each do |node|
          chain = Source::NodeChainer.chain(node, filename)
          next if chain.links.first.word == name
          clip = api_map.clip_at(location.filename, location.range.start)
          locals = clip.locals - [self]
          result = chain.infer(api_map, closure, locals)
          types.push result unless result.undefined?
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.try_parse(*types.map(&:tag))
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_type = pin.return_type
        true
      end

      private

      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
