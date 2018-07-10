module Solargraph
  module Pin
    class Method < Base
      attr_reader :scope
      attr_reader :visibility
      attr_reader :parameters

      def initialize location, namespace, name, docstring, scope, visibility, args
        super(location, namespace, name, docstring)
        @scope = scope
        @visibility = visibility
        @parameters = args
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

      def return_type
        @return_type = complex_types.first.tag if @return_type.nil? and !complex_types.empty?
        @return_type
      end

      def complex_types
        @complex_types ||= generate_complex_types
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          unless docstring.nil?
            param_tags = docstring.tags(:param)
            unless param_tags.nil? or param_tags.empty?
              @documentation += "\n\n"
              @documentation += "Params:\n"
              lines = []
              param_tags.each do |p|
                l = "* #{p.name}"
                l += " [#{p.types.join(', ')}]" unless p.types.empty?
                l += " #{p.text}"
                lines.push l
              end
              @documentation += lines.join("\n")
            end
          end
        end
        @documentation
      end

      # @todo This method was temporarily migrated directly from Suggestion
      # @return [Array<String>]
      def params
        if @params.nil?
          @params = []
          return @params if docstring.nil?
          param_tags = docstring.tags(:param)
          unless param_tags.empty?
            param_tags.each do |t|
              txt = t.name.to_s
              txt += " [#{t.types.join(',')}]" unless t.types.nil? or t.types.empty?
              txt += " #{t.text}" unless t.text.nil? or t.text.empty?
              @params.push txt
            end
          end
        end
        @params
      end

      private

      def generate_complex_types
        return [] if docstring.nil?
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
