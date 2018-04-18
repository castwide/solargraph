require 'yard'

module Solargraph
  module Pin
    class Helper
      include YARD::Templates::Helpers::HtmlHelper

      attr_accessor :object
      attr_accessor :serializer

      def initialize object = nil
        @object = object
      end

      def url_for(object)
        '.'
      end

      def html_markup_rdoc(text)
        # @todo The :rdoc markup class might not be immediately available.
        #   If not, return nil under the assumption that the problem will fix
        #   itself.
        return nil if markup_class(:rdoc).nil?
        super
      end

      def options
        if @options.nil?
          @options = YARD::Templates::TemplateOptions.new
          @options[:type] = :rdoc
        end
        @options
      end

      # HACK: The linkify method just returns the arguments as plain text
      def linkify *args
        args.join(', ')
      end
    end
  end
end
