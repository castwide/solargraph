require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The base language server data provider.
    #
    class Host
      include Solargraph::LanguageServer::UriHelpers

      attr_writer :resolvable

      attr_reader :workspace

      def initialize
        # @type [Hash<String, Solargraph::Source]
        @file_source = {}
        @change_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        start_change_thread
      end

      def workspace
        @workspace ||= Solargraph::Workspace.new(nil)
      end

      def resolvable
        @resolvable ||= {}
      end

      def api_map
        @api_map = Solargraph::ApiMap.new(workspace) if @api_map.nil? or @api_map.workspace != workspace
        @api_map
      end

      # @param options [Hash]
      def configure options
        @options = options
      end

      # @return [Hash]
      def options
        @options ||= {}
      end

      def cancel id
        @cancel.push id
      end

      def cancel? id
        @cancel.include? id
      end

      def clear id
        @cancel.delete id
      end

      def start request
        message = Message.select(request['method']).new(self, request)
        begin
          message.process
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
        end
        message
      end

      def read uri
        source = nil
        # @change_semaphore.synchronize {
          if @file_source.has_key?(uri)
            source = @file_source[uri]
          else
            filename = uri_to_file(uri)
            if workspace.has_file?(filename)
              source = workspace.source(filename)
              @file_source[uri] = source
            else
              # @todo Handle error?
            end
          end
        # }
        source
      end

      def open text_document
        @change_semaphore.synchronize do
          filename = uri_to_file(text_document['uri'])
          text = text_document['text'] || File.read(filename)
          #@file_source[text_document['uri']] = Solargraph::Source.fix(text, uri_to_file(text_document['uri']))
          #@file_source[text_document['uri']].version = text_document['version']
          if workspace.has_file?(filename)
            # @todo Synchronize text?
            @file_source[text_document['uri']] = workspace.source(filename)
            @file_source[text_document['uri']].synchronize([{'text' => text}], text_document['version'])
          else
            #@file_source[text_document['uri']]
            @file_source[text_document['uri']] = Solargraph::Source.fix(text, uri_to_file(text_document['uri']))
            @file_source[text_document['uri']].version = text_document['version']
          end
          #@change_queue.delete_if { |c| c['textDocument']['uri'] == text_document['uri'] and c['textDocument']['version'] < @file_source[text_document['uri']].version }
        end
      end

      def change params
        @change_semaphore.synchronize do
          if changing? params['textDocument']['uri']
            @change_queue.push params
          else
            source = read(params['textDocument']['uri'])
            if source.nil?
              # @todo Handle error
            else
              @change_queue.push params
              if params['textDocument']['version'] == source.version + params['contentChanges'].length
                source.synchronize(params['contentChanges'], params['textDocument']['version'])
                @change_queue.pop
              end
            end
          end
        end
      end

      def close filename
        @change_semaphore.synchronize { @file_source.delete filename }
      end

      def queue message
        @buffer_semaphore.synchronize do
          @buffer += message
        end
      end

      def flush
        tmp = nil
        @buffer_semaphore.synchronize do
          tmp = @buffer.clone
          @buffer.clear
        end
        tmp
      end

      # @param directory [String]
      def prepare directory
        path = normalize_separators(directory)
        if File.file?(File.join(path, '.solargraph.yml')) or File.file?(File.join(path, '.solargraph.yml'))
          @workspace = Workspace.new(path)
          api_map.refresh
        end
      end

      def send_notification method, params
        response = {
          jsonrpc: "2.0",
          method: method,
          params: params
        }
        json = response.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        queue envelope
      end

      def changing? file_uri
        result = false
        # @change_semaphore.synchronize {
          result = @change_queue.any?{|change| change['textDocument']['uri'] == file_uri}
        # }
        result
      end

      def stop
        @stopped = true
        EventMachine.stop
        exit
      end

      def stopped?
        @stopped
      end

      def synchronize &block
        @change_semaphore.synchronize do
          block.call
        end
      end

      private

      def start_change_thread
        Thread.new do
          until stopped?
            @change_semaphore.synchronize do
              #@change_queue.sort!{|a, b| a.version <=> b.version}
              @change_queue.delete_if do |change|
                filename = uri_to_file(change['textDocument']['uri'])
                source = read(change['textDocument']['uri'])
                if change['textDocument']['version'] == source.version + change['contentChanges'].length
                  source.synchronize(change['contentChanges'], change['textDocument']['version'])
                  true
                elsif change['textDocument']['version'] <= source.version
                  # @todo Is deleting outdated changes correct behavior?
                  true
                else
                  # @todo Change is out of order. Save it for later
                  false
                end
              end
            end
            sleep 1
          end
        end
      end

      def normalize_separators path
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end
    end
  end
end
