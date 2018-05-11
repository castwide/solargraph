module Solargraph
  module Pin
    class YardObject < Base
      COMPLETION_ITEM_KIND_MAP = {
        YARD::CodeObjects::ClassObject => Solargraph::LanguageServer::CompletionItemKinds::CLASS,
        YARD::CodeObjects::ModuleObject => Solargraph::LanguageServer::CompletionItemKinds::MODULE,
        YARD::CodeObjects::MethodObject => Solargraph::LanguageServer::CompletionItemKinds::METHOD,
        YARD::CodeObjects::ConstantObject => Solargraph::LanguageServer::CompletionItemKinds::CONSTANT
      }

      KIND_MAP = {
        YARD::CodeObjects::ClassObject => Pin::NAMESPACE,
        YARD::CodeObjects::ModuleObject => Pin::NAMESPACE,
        YARD::CodeObjects::MethodObject => Pin::METHOD,
        YARD::CodeObjects::ConstantObject => Pin::CONSTANT
      }

      # @return [YARD::CodeObjects::Base]
      attr_reader :code_object

      def initialize code_object, location
        # (c.to_s.split('::').last, detail: c.to_s, kind: kind, docstring: c.docstring, return_type: return_type, location: object_location(c))
        @code_object = code_object
        @location = location
      end

      def name
        # @name ||= code_object.to_s.split('::').last
        @name ||= code_object.name.to_s
      end

      def kind
        @kind ||= KIND_MAP[code_object.class] || Pin::KEYWORD
      end

      def completion_item_kind
        @completion_item_kind ||= COMPLETION_ITEM_KIND_MAP[code_object.class] || Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def docstring
        code_object.docstring
      end

      def return_type
        # @todo Get the return type
        if @return_type.nil?
          if code_object.kind_of?(YARD::CodeObjects::ClassObject)
            @return_type ||= "Class<#{path}>"
            return @return_type
          end
          if code_object.kind_of?(YARD::CodeObjects::ModuleObject)
            @return_type ||= "Module<#{path}>"
            return @return_type
          end        
          if Solargraph::CoreFills::CUSTOM_RETURN_TYPES.has_key?(path)
            @return_type = Solargraph::CoreFills::CUSTOM_RETURN_TYPES[path]
          else
            return nil if docstring.nil?
            tags = docstring.tags(:return)
            if tags.empty?
              overload = docstring.tag(:overload)
              return nil if overload.nil?
              tags = overload.tags(:return)
            end
            return nil if tags.empty?
            return nil if tags[0].types.nil?
            @return_type = tags[0].types[0]
          end
        end
        @return_type
      end

      def location
        @location
      end

      def path
        code_object.path
      end

      def namespace
        # @todo Is this right?
        code_object.namespace.to_s
      end

      def parameters
        @parameters ||= get_method_args
      end

      def visibility
        @visibility ||= (code_object.respond_to?(:visibility) ? code_object.visibility : :public)
      end

      def scope
        return nil unless code_object.is_a?(YARD::CodeObjects::MethodObject)
        code_object.scope
      end

      private

      def get_method_args
        return [] unless code_object.kind_of?(YARD::CodeObjects::MethodObject)
        args = []
        code_object.parameters.each { |a|
          p = a[0]
          unless a[1].nil?
            p += ' =' unless p.end_with?(':')
            p += " #{a[1]}"
          end
          args.push p
        }
        args
      end
    end
  end
end
