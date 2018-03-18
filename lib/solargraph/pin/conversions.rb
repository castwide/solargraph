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
            location: location,
            uid: object_id
          }
        }
      end

      # @return [Hash]
      def resolve_completion_item(api_map)
        extra = {}
        if return_type.nil? and self.kind_of?(Solargraph::Pin::BaseVariable)
          @return_type = api_map.infer_assignment_node_type(node, namespace)
        end
        # @todo Format the documentation
        extra[:documentation] = documentation
        completion_item.merge(extra)
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
        STDERR.puts "Parameters for #{name}: #{parameters.join(', ')}"
        detail = ''
        detail += "(#{parameters.join(', ')}) " unless parameters.empty?
        detail += "=> #{return_type}" unless return_type.nil?
        return nil if detail.empty?
        detail
      end
    end
  end
end
