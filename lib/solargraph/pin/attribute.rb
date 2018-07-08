module Solargraph
  module Pin
    class Attribute < Base
      # @return [Symbol] :reader or :writer
      attr_reader :access

      # @return [Symbol] :class or :instance
      attr_reader :scope

      def initialize location, namespace, name, docstring, access, scope
        super(location, namespace, name, docstring)
        @access = access
        @docstring = docstring
        @scope = scope
      end

      def kind
        Solargraph::Pin::ATTRIBUTE
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          @return_type = tag.types[0] unless tag.nil?
        end
        @return_type
      end

      def parameters
        # Since attributes are generally equivalent to methods, treat
        # them as methods without parameters
        []
      end
    end
  end
end
