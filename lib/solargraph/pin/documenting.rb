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

      def helper
        @helper ||= Solargraph::Pin::Helper.new
      end
    end
  end
end