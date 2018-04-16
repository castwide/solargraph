module Solargraph
  module Pin
    class Attribute < Base
      # @return [Symbol] :reader or :writer
      attr_reader :access

      def initialize location, namespace, name, docstring, access
        super(location, namespace, name, docstring)
        @access = access
        @docstring = docstring
      end

      def kind
        Solargraph::Pin::ATTRIBUTE
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end

      def path
        @path ||= namespace + '#' + name
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          @return_type = tag.types[0] unless tag.nil?
        end
        @return_type
      end
    end
  end
end
