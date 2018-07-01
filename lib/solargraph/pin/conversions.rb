module Solargraph
  module Pin
    # @todo Move this stuff. It should be the responsibility of the language server.
    module Conversions
      # @return [Hash]
      def completion_item
        @completion_item ||= {
          label: name,
          kind: completion_item_kind,
          detail: detail,
          data: {
            path: path,
            return_type: return_type,
            location: location
          }
        }
      end

      # @return [Hash]
      def resolve_completion_item
        if @resolve_completion_item.nil?
          extra = {}
          alldoc = ''
          alldoc += link_documentation(path) unless path.nil?
          alldoc += "\n\n" unless alldoc.empty?
          alldoc += documentation unless documentation.nil?
          extra[:documentation] = alldoc unless alldoc.empty?
          @resolve_completion_item = completion_item.merge(extra)
        end
        @resolve_completion_item
      end

      # @return [Hash]
      def signature_help
        @signature_help ||= {
          label: name + '(' + parameters.join(', ') + ')',
          documentation: documentation
        }
      end

      # @return [String]
      def detail
        if @detail.nil?
          @detail = ''
          @detail += "(#{parameters.join(', ')}) " unless kind != Pin::METHOD or parameters.empty?
          @detail += "=> #{return_type}" unless return_type.nil?
          @detail.strip!
        end
        return nil if @detail.empty?
        @detail
      end

      private

      def link_documentation path
        @link_documentation ||= "[#{path}](solargraph:/document?query=#{URI.encode(path)})"
      end
    end
  end
end
