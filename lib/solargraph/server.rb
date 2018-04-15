require 'sinatra/base'
require 'thread'
require 'yard'
require 'open3'
require 'shellwords'

module Solargraph
  class Server < Sinatra::Base

    set :port, 7657
    set :server, :webrick

    # @@api_hash = {}
    @@semaphore = Mutex.new

    @@library = Solargraph::Library.new

    after do
      GC.start
    end

    def self.wait
      @@semaphore.lock
      @@semaphore.unlock
    end

    post '/diagnostics' do
      content_type :json
      severities = {
        'refactor' => 4,
        'convention' => 3,
        'warning' => 2,
        'error' => 1,
        'fatal' => 1
      }
      begin
        filename = params['filename']
        text = params['text']
        o, e, s = Open3.capture3("bundle exec rubocop -f j -s #{Shellwords.escape(filename)}", stdin_data: text)
        STDERR.puts e unless e.nil? or e.empty?
        resp = JSON.parse(o)
        diagnostics = []
        if resp['summary']['offense_count'] > 0
          resp['files'].each do |file|
            file['offenses'].each do |off|
              diag = {
                range: {
                  start: {
                    line: off['location']['start_line'] - 1,
                    character: off['location']['start_column'] - 1
                  },
                  end: {
                    line: off['location']['last_line'] - 1,
                    character: off['location']['last_column']
                  }
                },
                # 1 = Error, 2 = Warning, 3 = Information, 4 = Hint
                severity: severities[off['severity']],
                source: off['cop_name'],
                message: off['message'].gsub(/^#{off['cop_name']}\:/, '')
              }
              diagnostics.push diag
            end
          end
        end
        { "status" => "ok", "data" => diagnostics }.to_json
      rescue Exception => e
        send_exception e
      end
    end

    post '/prepare' do
      content_type :json
      begin
        workspace = params['workspace'].to_s.gsub(/\\/, '/')
        STDERR.puts "Preparing #{workspace}"
        @@library = Solargraph::Library.load(workspace) unless workspace.empty?
        { "status" => "ok"}.to_json
      rescue Exception => e
        send_exception e
      end
    end

    post '/update' do
      content_type :json
      begin
        filename = params['filename'].to_s.gsub(/\\/, '/')
        @@library.open filename, File.read(filename), 0
        { "status" => "ok"}.to_json
      rescue Exception => e
        send_exception e
      end
    end

    post '/suggest' do
      content_type :json
      begin
        filename = params['filename'].to_s.gsub(/\\/, '/')
        @@library.open filename, params['text'], 0
        @@library.checkout filename
        @@library.refresh
        with_all = params['all'] == '1' ? true : false
        completion = @@library.completions_at(filename, params['line'].to_i, params['column'].to_i)
        JSON.generate({ "status" => "ok", "suggestions" => completion.pins.map{|s| Suggestion.pull(s).as_json(all: with_all)} })
      rescue Exception => e
        send_exception e
      end
    end

    post '/signify' do
      content_type :json
      begin
        filename = params['filename'].to_s.gsub(/\\/, '/')
        @@library.open filename, params['text'], 0
        @@library.checkout filename
        @@library.refresh
        sugg = @@library.signatures_at(filename, params['line'].to_i, params['column'].to_i)
        { "status" => "ok", "suggestions" => sugg.map{|s| Suggestion.pull(s).as_json(all: true)} }.to_json
      rescue Exception => e
        send_exception e
      end
    end

    post '/resolve' do
      content_type :json
      begin
        result = @@library.get_path_pins(params['path'])
        { "status" => "ok", "suggestions" => result.map{|s| Suggestion.pull(s).as_json(all: true)} }.to_json
      rescue Exception => e
        send_exception e
      end
    end

    post '/define' do
      content_type :json
      begin
        filename = params['filename'].to_s.gsub(/\\/, '/')
        @@library.open filename, params['text'], 0
        @@library.checkout filename
        sugg = @@library.definitions_at(filename, params['line'].to_i, params['column'].to_i)
        { "status" => "ok", "suggestions" => sugg.map{|s| Suggestion.pull(s).as_json(all: true)} }.to_json
      rescue Exception => e
        send_exception e
      end
    end

    # @deprecated Use /define instead.
    post '/hover' do
      content_type :json
      begin
        filename = params['filename'].to_s.gsub(/\\/, '/')
        @@library.open filename, params['text'], 0
        @@library.refresh
        @@library.checkout filename
        sugg = @@library.definitions_at(filename, params['line'].to_i, params['column'].to_i)
        { "status" => "ok", "suggestions" => sugg.map{|s| Suggestion.pull(s).as_json(all: true)} }.to_json
      rescue Exception => e
        send_exception e
      end
    end

    get '/search' do
      @results = @@library.search(params['query'])
      erb :search, locals: { query: params['query'], results: @results }
    end

    get '/document' do
      @objects = @@library.document(params['query'])
      erb :document, locals: { objects: @objects }
    end

    def htmlify text
      rdoc_to_html text
    end

    def rdoc_to_html text
      h = Helpers.new
      h.html_markup_rdoc(text)
    end

    def ruby_to_html code
      h = Helpers.new
      h.html_markup_ruby(code)
    end

    def send_exception e
      STDERR.puts e
      STDERR.puts e.backtrace.join("\n")
      { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
    end

    class Helpers
      include YARD::Templates::Helpers::HtmlHelper

      attr_accessor :object
      attr_accessor :serializer

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
