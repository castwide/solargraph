module Solargraph
  module Pin
    module Conversions
      # @return [Hash]
      def completion_item
        {
          label: name,
          insert: name.sub(/=$/, ' = '),
          kind: kind,
          detail: completion_item_detail,
          data: {
            path: path,
            return_type: return_type,
            location: location
          }
        }
      end

      # @return [Hash]
      def resolve_completion_item(api_map)
        extra = {}
        resolve api_map
        # if return_type.nil? and self.kind_of?(Solargraph::Pin::BaseVariable)
        #   @return_type = api_map.infer_assignment_node_type(node, namespace)
        # end
        # @todo Format the documentation
        extra[:documentation] = documentation
        completion_item.merge(extra)
      end

      # @param api_map [Solargraph::ApiMap]
      def hover(api_map)
        info = ''
        if self.kind_of?(Solargraph::Pin::BaseVariable)
          rt = return_type
          rt = api_map.infer_assignment_node_type(node, namespace) if rt.nil?
          info.concat link_documentation(rt) unless rt.nil?
        else
          info.concat link_documentation(path) unless path.nil?
          info.concat "\n\n#{ReverseMarkdown.convert(documentation)}" unless documentation.nil? or documentation.empty?
          info
        end
        info
      end

      # @return [Hash]
      def signature_help
        {
          label: name + '(' + arguments.join(', ') + ')',
          documentation: documentation
        }
      end

      private

      def completion_item_detail
        detail = ''
        detail += "(#{parameters.join(', ')}) " unless parameters.empty?
        detail += "=> #{return_type}" unless return_type.nil?
        return nil if detail.empty?
        detail
      end

      def link_documentation path
        uri = "solargraph:/document?query=" + URI.encode(path)
        "[#{path}](#{uri})"
      end  
    end
  end
end
