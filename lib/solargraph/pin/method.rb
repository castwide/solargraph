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
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          if tag.nil?
            ol = docstring.tag(:overload)
            tag = ol.tag(:return) unless ol.nil?
          end
          @return_type = tag.types[0] unless tag.nil? or tag.types.nil?
        end
        @return_type
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
    end
  end
end
