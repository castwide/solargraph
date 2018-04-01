require 'ostruct'
require 'tilt'
require 'redcarpet'

module Solargraph
  class Page
    class Binder < OpenStruct
      def initialize locals, render_method
        super(locals)
        define_singleton_method :render do |template, layout: false, locals: {}|
          render_method.call(template, layout: layout, locals: locals)
        end
        define_singleton_method :erb do |template, layout: false, locals: {}|
          render_method.call(template, layout: layout, locals: locals)
        end        
      end

      def htmlify text
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(prettify: true), fenced_code_blocks: true)
        helper = Solargraph::Pin::Helper.new
        conv = ReverseMarkdown.convert(helper.html_markup_rdoc(text), github_flavored: true)
        result = markdown.render(conv)
        STDERR.puts result
        result
      end

      def ruby_to_html code
        code
      end
    end
    private_constant :Binder

    def initialize directory
      @render_method = proc { |template, layout: false, locals: {}|
        binder = Binder.new(locals, @render_method)
        if layout
          Tilt::ERBTemplate.new(File.join(directory, 'layout.erb')).render(binder) do
            Tilt::ERBTemplate.new(File.join(directory, "#{template}.erb")).render(binder)
          end
        else
          Tilt::ERBTemplate.new(File.join(directory, "#{template}.erb")).render(binder)
        end
      }
    end

    def render template, layout: true, locals: {}
      @render_method.call(template, layout: layout, locals: locals)
    end
  end
end
