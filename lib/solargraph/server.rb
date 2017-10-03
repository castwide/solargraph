require 'sinatra/base'
require 'thread'
require 'yard'

module Solargraph
  class Server < Sinatra::Base

    set :port, 7657
    set :server, :webrick

    @@api_hash = {}
    @@semaphore = Mutex.new

    after do
      GC.start
    end

    def self.wait
      @@semaphore.lock
      @@semaphore.unlock
    end

    post '/prepare' do
      content_type :json
      STDERR.puts "Preparing #{params['workspace']}"
      Server.prepare_workspace params['workspace']
      { "status" => "ok"}.to_json
    end

    post '/update' do
      content_type :json
      # @type [Solargraph::ApiMap]
      api_map = @@api_hash[params['workspace']]
      unless api_map.nil?
        api_map.update params['filename']
      end
      { "status" => "ok"}.to_json
    end

    post '/suggest' do
      content_type :json
      begin
        sugg = []
        workspace = params['workspace']
        @@semaphore.synchronize {
          code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: @@api_hash[workspace], cursor: [params['line'].to_i, params['column'].to_i])
          offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
          sugg = code_map.suggest_at(offset, with_snippets: params['with_snippets'] == '1' ? true : false, filtered: (params['filtered'] || false))
        }
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    post '/signify' do
      content_type :json
      begin
        sugg = []
        workspace = params['workspace'] || nil
        @@semaphore.synchronize {
          code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: @@api_hash[workspace], cursor: [params['line'].to_i, params['column'].to_i])
          offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
          sugg = code_map.signatures_at(offset)
        }
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    post '/hover' do
      content_type :json
      begin
        sugg = []
        workspace = params['workspace'] || nil
        @@semaphore.synchronize {
          code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: @@api_hash[workspace], cursor: [params['line'].to_i, params['column'].to_i])
          offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
          sugg = code_map.resolve_object_at(offset)
        }
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    get '/search' do
      workspace = params['workspace']
      api_map = @@api_hash[workspace]
      required = []
      unless api_map.nil?
        required.concat api_map.required
      end
      yard = YardMap.new(required: required, workspace: workspace)
      @results = yard.search(params['query'])
      erb :search
    end

    get '/document' do
      workspace = params['workspace']
      api_map = @@api_hash[workspace]
      required = []
      unless api_map.nil?
        required.concat api_map.required
      end
      yard = YardMap.new(required: required, workspace: workspace)
      @objects = yard.document(params['query'])
      erb :document
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

    class << self
      def run!
        super
      end

      def prepare_workspace directory
        Thread.new do
          @@semaphore.synchronize do
            api_map = Solargraph::ApiMap.new(directory)
            @@api_hash[directory] = api_map
          end
        end
      end
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
