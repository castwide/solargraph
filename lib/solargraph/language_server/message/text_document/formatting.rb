# frozen_string_literal: true

require 'rubocop'
require 'securerandom'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Formatting < Base
          def process
            filename = uri_to_file(params['textDocument']['uri'])
            # Make the temp file in the original file's directory so RuboCop
            # detects the correct configuration
            tempfile = File.join(File.dirname(filename), "_tmp_#{SecureRandom.hex(8)}_#{File.basename(filename)}")
            original = host.read_text(params['textDocument']['uri'])
            File.write tempfile, original
            begin
              options, paths = RuboCop::Options.new.parse(['-a', '-f', 'fi', tempfile])
              RuboCop::Runner.new(options, RuboCop::ConfigStore.new).run(paths)
              result = File.read(tempfile)
              File.unlink tempfile
              format original, result
            rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
              set_error(Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}")
              File.unlink tempfile
            end
          end

          private

          # @param original [String]
          # @param result [String]
          # @return [void]
          def format original, result
            if original.end_with?("\n")
              ending = {
                line: original.lines.length,
                character: 0
              }
            else
              ending = {
                line: original.lines.length - 1,
                character: original.lines.last.length
              }
            end
            set_result(
              [
                {
                  range: {
                    start: {
                      line: 0,
                      character: 0
                    },
                    end: ending
                  },
                  newText: result
                }
              ]
            )
          end
        end
      end
    end
  end
end
