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
      begin
        Server.prepare_workspace params['workspace']
        { "status" => "ok"}.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    post '/update' do
      content_type :json
      begin
        workspace = find_local_workspace(params['filename'], params['workspace'])
        # @type [Solargraph::ApiMap]
        api_map = get_api_map(workspace)
        unless api_map.nil?
          api_map.update params['filename']
        end
        { "status" => "ok"}.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    post '/suggest' do
      content_type :json
      begin
        sugg = []
        workspace = find_local_workspace(params['filename'], params['workspace'])
        api_map = get_api_map(workspace)
        with_all = params['all'] == '1' ? true : false
        code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: api_map, cursor: [params['line'].to_i, params['column'].to_i])
        offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
        sugg = code_map.suggest_at(offset, with_snippets: params['with_snippets'] == '1' ? true : false, filtered: true)
        JSON.generate({ "status" => "ok", "suggestions" => sugg.map{|s| s.as_json(all: with_all)} })
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
        workspace = find_local_workspace(params['filename'], params['workspace'])
        api_map = get_api_map(workspace)
        code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: api_map, cursor: [params['line'].to_i, params['column'].to_i])
        offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
        sugg = code_map.signatures_at(offset)
        { "status" => "ok", "suggestions" => sugg.map{|s| s.as_json(all: true)} }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    post '/resolve' do
      content_type :json
      begin
        workspace = find_local_workspace(params['filename'], params['workspace'])
        result = []
        api_map = get_api_map(workspace)
        unless api_map.nil?
          # @todo Get suggestions that match the path
          result.concat api_map.get_path_suggestions(params['path'])
        end
        { "status" => "ok", "suggestions" => result.map{|s| s.as_json(all: true)} }.to_json
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
        workspace = find_local_workspace(params['filename'], params['workspace'])
        api_map = get_api_map(workspace)
        code_map = CodeMap.new(code: params['text'], filename: params['filename'], api_map: @@api_hash[workspace], cursor: [params['line'].to_i, params['column'].to_i])
        offset = code_map.get_offset(params['line'].to_i, params['column'].to_i)
        sugg = code_map.resolve_object_at(offset)
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
      end
    end

    get '/search' do
      workspace = params['workspace']
      api_map = get_api_map(workspace) || Solargraph::ApiMap.new
      @results = api_map.search(params['query'])
      erb :search
    end

    get '/document' do
      workspace = params['workspace']
      api_map = get_api_map(workspace) || Solargraph::ApiMap.new
      @objects = api_map.document(params['query'])
      erb :document
    end

    # @return [Solargraph::ApiMap]
    def self.get_api_map workspace
      api_map = nil
      @@semaphore.synchronize {
        api_map = @@api_hash[workspace]
      }
      api_map
    end

    # @return [Solargraph::ApiMap]
    def get_api_map workspace
      Server.get_api_map workspace
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

    def find_local_workspace file, workspace
      unless file.nil? or workspace.nil?
        return nil unless file.start_with?(workspace)
        dir = File.dirname(file)
        while dir.start_with?(workspace)
          return dir if @@api_hash.has_key?(dir)
          dir = File.dirname(dir)
        end
      end
      workspace
    end

    class << self
      def prepare_workspace directory
        Thread.new do
          configs = Dir['**/.solargraph.yml']
          resolved = []
          configs.each do |cf|
            dir = File.dirname(cf)
            generate_api_map dir
            resolved.push dir
          end
          generate_api_map directory unless resolved.include?(directory)
        end
      end

      def generate_api_map(directory)
        api_map = Solargraph::ApiMap.new(cf)
        api_map.yard_map
        @@semaphore.synchronize do
          @@api_hash[directory] = api_map
        end
      end

      def run!
        Thread.new do
          while true
            check_workspaces
            sleep 1
          end
        end
        super
      end

      def check_workspaces
        @@semaphore.synchronize do
          changed = {}
          @@api_hash.each_pair do |w, a|
            next unless a.changed?
            STDERR.puts "Reloading changed workspace #{w}"
            n = Solargraph::ApiMap.new(w)
            changed[w] = n
          end
          changed.each_pair do |w, a|
            @@api_hash[w] = a
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
