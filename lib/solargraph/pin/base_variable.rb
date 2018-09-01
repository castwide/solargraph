module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Source::NodeMethods

      attr_reader :context

      def initialize location, namespace, name, comments, assignment, literal, context
        super(location, namespace, name, comments)
        @assignment = assignment
        @literal = literal
        @context = context
      end

      def signature
        @signature ||= resolve_node_signature(@assignment)
      end

      def scope
        @scope ||= (context.kind == Pin::METHOD and context.scope == :instance ? :instance : :class)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_complex_type
        @return_complex_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type == 'NilClass'
      end

      def variable?
        true
      end

      # @param api_map [ApiMap]
      def infer api_map
        result = super
        return result if result.defined? or @assignment.nil?
        # chain = Source::Chain.new(filename, @assignment)
        # @todo Use NodeChainer
        chain = SourceMap::NodeChainer.chain(location.filename, @assignment)
        # @todo Is there another way besides the apimap?
        fragment = api_map.fragment_at(location.filename, location.range.start)
        locals = fragment.locals - [self]
        chain.infer(api_map, context, locals)
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_complex_type = pin.return_complex_type
        true
      end

      protected

      attr_reader :assignment

      private

      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.parse(*tag.types) unless tag.nil?
        return ComplexType.parse(@literal) unless @literal.nil?
        ComplexType.new
      end
    end
  end
end
