require 'open3'
require 'shellwords'
# require 'rubocop'
require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The language server protocol's data provider. Hosts are responsible for
    # querying the library and processing messages.
    #
    class Host
      include Solargraph::LanguageServer::UriHelpers

      # attr_reader :workspace
      attr_reader :library

      def initialize
        @change_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        @library = nil # @todo How to initialize the library
        start_change_thread
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

      def change params
        @change_semaphore.synchronize do
          if changing? params['textDocument']['uri']
            @change_queue.push params
          else
            source = library.checkout(uri_to_file(params['textDocument']['uri']))
            @change_queue.push params
            if params['textDocument']['version'] == source.version + params['contentChanges'].length
              source.synchronize(params['contentChanges'], params['textDocument']['version'])
              library.refresh
              @change_queue.pop
            end
          end
        end
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
        @library = Solargraph::Library.load(path)
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
        @change_queue.any?{|change| change['textDocument']['uri'] == file_uri}
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

      def diagnose file_uri
        publish_diagnostics file_uri
      end

      private

      def start_change_thread
        Thread.new do
          until stopped?
            changed = false
            @change_semaphore.synchronize do
              @change_queue.delete_if do |change|
                filename = uri_to_file(change['textDocument']['uri'])
                source = read(change['textDocument']['uri'])
                if change['textDocument']['version'] == source.version + change['contentChanges'].length
                  source.synchronize(change['contentChanges'], change['textDocument']['version'])
                  changed = true
                  true
                elsif change['textDocument']['version'] <= source.version
                  # @todo Is deleting outdated changes correct behavior?
                  changed = true
                  true
                else
                  # @todo Change is out of order. Save it for later
                  false
                end
              end
              library.refresh if changed
            end
            sleep 1
          end
        end
      end

      def normalize_separators path
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end

      def version_hash
        @version_hash ||= {}
      end

      def publish_diagnostics uri
        return if changing?(uri)
        severities = {
          'refactor' => 4,
          'convention' => 3,
          'warning' => 2,
          'error' => 1,
          'fatal' => 1
        }
        filename = uri_to_file(uri)
        text = library.read_code(filename)
        cmd = "rubocop -f j -s #{Shellwords.escape(filename)}"
        o, e, s = Open3.capture3(cmd, stdin_data: text)
        unless changing?(uri)
          resp = JSON.parse(o)
          if resp['summary']['offense_count'] > 0
            diagnostics = []
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
            send_notification "textDocument/publishDiagnostics", {
              uri: uri,
              diagnostics: diagnostics
            }
          end
        end
      rescue Exception => e
        STDERR.puts "#{e}"
        STDERR.puts "#{e.backtrace}"
      end
    end
  end
end
