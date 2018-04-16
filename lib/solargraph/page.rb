require 'ostruct'
require 'tilt'
require 'redcarpet'
require 'htmlentities'
require 'coderay'

module Solargraph
  class Page
    class SolargraphRenderer < Redcarpet::Render::HTML
      def normal_text text
        HTMLEntities.new.encode(text, :named)
      end
      def block_code code, language
        CodeRay.scan(code, language || :ruby).div
      end
    end
    private_constant :SolargraphRenderer

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
        markdown = Redcarpet::Markdown.new(SolargraphRenderer.new(prettify: true), fenced_code_blocks: true)
        markdown.render(conv)
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
