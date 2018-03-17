module Solargraph
  module Pin
    module Conversions
      # @return [Hash]
      def to_completion_item
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
      def to_resolved_item(api_map = nil)
        extra = {}
        extra[:documentation] = docstring.to_s
        if return_type.nil? and !api_map.nil?
          # @todo: resolve return type from api_map
          extra[:return_type] = return_type
        end
        to_completion_item.merge(extra)
      end

      private

      def completion_item_detail
        detail = ''
        detail += "(#{parameters.join(', ')}) " unless parameters.empty?
        detail += "=> #{return_type}" unless return_type.nil?
        return nil if detail.empty?
        detail
      end

      def completion_item_documentation
      end
    end
  end
end
