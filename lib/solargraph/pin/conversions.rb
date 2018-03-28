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
      def resolve_completion_item
        extra = {}
        # @todo Format the documentation
        extra[:documentation] = documentation
        completion_item.merge(extra)
      end

      # @param api_map [Solargraph::ApiMap]
      def hover
        info = ''
        if self.kind_of?(Solargraph::Pin::BaseVariable)
          STDERR.puts "Link to #{return_type}"
          info.concat link_documentation(return_type) unless return_type.nil?
        else
          info.concat link_documentation(path) unless path.nil?
        end
        info.concat "\n\n#{ReverseMarkdown.convert(documentation)}" unless documentation.nil? or documentation.empty?
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
