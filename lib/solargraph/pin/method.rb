module Solargraph
  module Pin
    class Method < Base
      # @return [Symbol] :instance or :class
      attr_reader :scope

      # @return [Symbol] :public, :private, or :protected
      attr_reader :visibility

      # @return [Array<String>]
      attr_reader :parameters

      def initialize location, namespace, name, comments, scope, visibility, args
        super(location, namespace, name, comments)
        @scope = scope
        @visibility = visibility
        @parameters = args
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map{|p| p.split(/[ =:]/).first}
      end

      def kind
        Solargraph::Pin::METHOD
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      # @return [Integer]
      def symbol_kind
        LanguageServer::SymbolKinds::METHOD
      end

      def return_complex_types
        @return_complex_types ||= generate_complex_types
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          param_tags = docstring.tags(:param)
          unless param_tags.nil? or param_tags.empty?
            @documentation += "\n\n"
            @documentation += "Params:\n"
            lines = []
            param_tags.each do |p|
              l = "* #{p.name}"
              l += " [#{p.types.join(', ')}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
        end
        @documentation
      end

      def nearly? other
        return false unless super
        parameters == other.parameters and
          scope == other.scope and
          visibility == other.visibility
      end

      private

      def generate_complex_types
        tag = docstring.tag(:return)
        if tag.nil?
          ol = docstring.tag(:overload)
          tag = ol.tag(:return) unless ol.nil?
        end
        return [] if tag.nil?
        ComplexType.parse *tag.types
      end
    end
  end
end
