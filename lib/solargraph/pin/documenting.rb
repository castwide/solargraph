module Solargraph
  module Pin
    module Documenting
      # @return [String]
      def documentation
        if @documentation.nil?
          @documentation = ReverseMarkdown.convert(helper.html_markup_rdoc(docstring), github_flavored: true)
          @documentation.strip!
        end
        @documentation
      end

      # True if the suggestion has documentation.
      # Useful for determining whether a client should resolve a suggestion's
      # path to retrieve more information about it.
      #
      # @return [Boolean]
      def has_doc?
        !docstring.all.empty?
      end

      def helper
        @helper ||= Solargraph::Pin::Helper.new
      end
    end
  end
end