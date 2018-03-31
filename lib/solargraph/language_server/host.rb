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
        @diagnostics_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        @library = nil # @todo How to initialize the library
        start_change_thread
        start_diagnostics_thread
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

      def open uri, text, version
        library.open uri_to_file(uri), text, version
        @change_semaphore.synchronize { @diagnostics_queue.push uri }
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
              @diagnostics_queue.push params['textDocument']['uri']
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

      private

      def start_change_thread
        Thread.new do
          until stopped?
            @change_semaphore.synchronize do
              begin
                changed = false
                @change_queue.delete_if do |change|
                  filename = uri_to_file(change['textDocument']['uri'])
                  source = read(change['textDocument']['uri'])
                  if change['textDocument']['version'] == source.version + change['contentChanges'].length
                    source.synchronize(change['contentChanges'], change['textDocument']['version'])
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    true
                  elsif change['textDocument']['version'] <= source.version
                    # @todo Is deleting outdated changes correct behavior?
                    STDERR.puts "Deleting stale change"
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    true
                  else
                    # @todo Change is out of order. Save it for later
                    STDERR.puts "Kept in queue: #{change['textDocument']['uri']} from #{source.version} to #{change['textDocument']['version']}"
                    false
                  end
                end
                STDERR.puts "#{@change_queue.length} pending" unless @change_queue.empty?
                library.refresh if changed
              rescue Exception => e
                STDERR.puts e.message
              end
            end
          sleep 0.1
          end
        end
      end

      def start_diagnostics_thread
        Thread.new do
          until stopped?
            unless @change_semaphore.locked?
              begin
                current = nil
                @change_semaphore.synchronize do
                  current = @diagnostics_queue.shift
                end
                unless current.nil?
                  already_changing = false
                  @change_semaphore.synchronize { already_changing = (changing?(current) or @diagnostics_queue.include?(current)) }
                  unless already_changing
                    resp = read_diagnostics(current)
                    @change_semaphore.synchronize { already_changing = (changing?(current) or @diagnostics_queue.include?(current)) }
                    publish_diagnostics current, resp unless already_changing
                  end
                end
              rescue Exception => e
                STDERR.puts e.message
              end
            end
            sleep 0.1
          end
        end
      end

      def normalize_separators path
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end

      def version_hash
        @version_hash ||= {}
      end

      def read_diagnostics uri
        begin
          filename = nil
          text = nil
          @change_semaphore.synchronize do
            filename = uri_to_file(uri)
            text = library.read_code(filename)
          end
          cmd = "rubocop -f j -s #{Shellwords.escape(filename)}"
          o, e, s = Open3.capture3(cmd, stdin_data: text)
          JSON.parse(o)
        rescue Exception => e
          STDERR.puts "#{e}"
          STDERR.puts "#{e.backtrace}"
          nil
        end
      end

      def publish_diagnostics uri, resp
        severities = {
          'refactor' => 4,
          'convention' => 3,
          'warning' => 2,
          'error' => 1,
          'fatal' => 1
        }
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
  end
end
