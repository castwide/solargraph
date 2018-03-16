module Solargraph
  module Pin
    module Conversions
      def to_completion_item
        {
          label: name,
          kind: kind,
          detail: completion_item_detail,
          # @todo Format the documentation
          documentation: docstring.to_s,
          data: {
            path: path,
            return_type: return_type,
            location: "#{source.filename}:#{node.location.expression.line - 1}:#{node.location.expression.column}"
          }
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
    end
  end
end
