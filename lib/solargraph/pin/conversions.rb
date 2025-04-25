# frozen_string_literal: true

require 'cgi'

module Solargraph
  module Pin
    # @todo Move this stuff. It should be the responsibility of the language server.
    # @todo abstract methods below should be verified to be overridden
    #   by type checker when mixin included by non-abstract class
    module Conversions
      # @!parse
      #   include Documenting
      #   include Common

      # @return [Integer]
      # @abstract
      def completion_item_kind
        raise NotImplementedError
      end

      # @abstract
      # @return [Boolean]
      def deprecated?
        raise NotImplementedError
      end

      # @abstract
      def probed?
        raise NotImplementedError
      end

      # @abstract
      def proxied?
        raise NotImplementedError
      end

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
        @resolve_completion_item ||= begin
          extra = {}
          alldoc = ''
          # alldoc += link_documentation unless link_documentation.nil?
          # alldoc += "\n\n" unless alldoc.empty?
          alldoc += documentation unless documentation.nil?
          extra[:documentation] = alldoc unless alldoc.empty?
          completion_item.merge(extra)
        end
      end

      # @return [::Array<Hash>]
      def signature_help
        []
      end

      # @return [String, nil]
      def detail
        # This property is not cached in an instance variable because it can
        # change when pins get proxied.
        detail = String.new
        detail += "=#{probed? ? '~' : (proxied? ? '^' : '>')} #{return_type.to_s}" unless return_type.undefined?
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

      # @return [String, nil]
      def text_documentation
        this_path = path || name || return_type.tag
        return nil if this_path == 'undefined'
        escape_brackets this_path
      end

      # @return [void]
      def reset_conversions
        @completion_item = nil
        @resolve_completion_item = nil
        @signature_help = nil
        @detail = nil
        @link_documentation = nil
      end

      private

      # @return [String, nil]
      def generate_link
        this_path = path || name || return_type.tag
        return nil if this_path == 'undefined'
        return nil if this_path.nil? || this_path == 'undefined'
        return this_path if path.nil?
        "[#{escape_brackets(this_path).gsub('_', '\\\\_')}](solargraph:/document?query=#{CGI.escape(this_path)})"
      end

      # @param text [String]
      # @return [String]
      def escape_brackets text
        # text.gsub(/(\<|\>)/, "\\#{$1}")
        text.gsub("<", '\<').gsub(">", '\>')
      end
    end
  end
end
