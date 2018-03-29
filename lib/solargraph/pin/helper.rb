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

      def options
        @options ||= YARD::Templates::TemplateOptions.new
      end

      # HACK: The linkify method just returns the arguments as plain text
      def linkify *args
        args.join(', ')
      end
    end
  end
end
