# frozen_string_literal: true

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
            return_type: return_type.tag,
            location: (location ? location.to_hash : nil),
            deprecated: deprecated?
          }
        }
      end

      # @return [Hash]
      def resolve_completion_item
        if @resolve_completion_item.nil?
          extra = {}
          alldoc = ''
          # alldoc += link_documentation unless link_documentation.nil?
          # alldoc += "\n\n" unless alldoc.empty?
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
        # This property is not cached in an instance variable because it can
        # change when pins get proxied.
        detail = String.new
        detail += "(#{parameters.join(', ')}) " unless !is_a?(Pin::BaseMethod) or parameters.empty?
        detail += "=#{probed? ? '~' : (proxied? ? '^' : '>')} #{return_type}" unless return_type.undefined?
        detail.strip!
        return nil if detail.empty?
        detail
      end

      # Get a markdown-flavored link to a documentation page.
      #
      # @return [String]
      def link_documentation
        @link_documentation ||= generate_link
      end

      def text_documentation
        this_path = path || return_type.tag
        return nil if this_path == 'undefined'
        this_path
      end

      def reset_conversions
        @completion_item = nil
        @resolve_completion_item = nil
        @signature_help = nil
        @detail = nil
        @link_documentation = nil
      end

      private

      def generate_link
        this_path = text_documentation
        return nil if this_path.nil? || this_path == 'undefined'
        "[#{this_path.gsub('_', '\\\\_')}](solargraph:/document?query=#{URI.escape(this_path)})"
      end
    end
  end
end
