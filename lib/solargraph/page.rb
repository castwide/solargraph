require 'ostruct'
require 'tilt'
require 'kramdown'
require 'htmlentities'
require 'coderay'
require 'reverse_markdown'

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
        helper = Solargraph::Pin::Helper.new
        html = helper.html_markup_rdoc(text)
        conv = ReverseMarkdown.convert(html, github_flavored: true)
        Kramdown::Document.new(
          conv,
          input: 'GFM',
          entity_output: :symbolic,
          syntax_highlighter_opts: {
            block: {
              line_numbers: false,
            },
            default_lang: :ruby
          },
        ).to_html
      end

      def ruby_to_html code
        code
      end
    end
    private_constant :Binder

    def initialize directory = VIEWS_PATH
      directory = VIEWS_PATH if directory.nil? or !File.directory?(directory)
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
