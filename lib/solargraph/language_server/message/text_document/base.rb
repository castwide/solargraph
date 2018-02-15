require 'open3'
require 'shellwords'
#require 'mktmpdir'
require 'rubocop'
require 'thread'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Base < Solargraph::LanguageServer::Message::Base
          class << self
            def start_diagnostics uri
              diagnostics_semaphore.synchronize {
                diagnostics_queue.push uri
              }
            end

            def more_diagnostics? uri
              result = nil
              diagnostics_semaphore.synchronize {
                result = diagnostics_queue.include?(uri)
              }
              result
            end

            def finish_diagnostics uri
              diagnostics_semaphore.synchronize {
                diagnostics_queue.slice!(diagnostics_queue.index(uri)) if diagnostics_queue.include?(uri)
              }              
            end

            private

            def diagnostics_semaphore
              @diagnostics_semaphore ||= Mutex.new
            end

            def diagnostics_queue
              @diagnostics_queue ||= []
            end
          end

          attr_reader :filename

          def uri_to_file uri
            URI.decode(uri.gsub(/^file\:\/\/\/?/, ''))
          end

          def post_initialize
            @filename = uri_to_file(params['textDocument']['uri'])
          end

          protected

          def publish_diagnostics
            severities = {
              'refactor' => 4,
              'convention' => 3,
              'warning' => 2,
              'error' => 1,
              'fatal' => 1
            }
            uri = params['textDocument']['uri']
            Base.start_diagnostics uri
            text = host.read(filename)
            return if text.nil? or text.empty?
            cmd = "rubocop -f j -s #{Shellwords.escape(filename)}"
            o, e, s = Open3.capture3(cmd, stdin_data: text)
            Base.finish_diagnostics(uri)
            unless Base.more_diagnostics?(uri)
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
                host.send_notification "textDocument/publishDiagnostics", {
                  uri: params['textDocument']['uri'],
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
  end
end
