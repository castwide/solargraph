# frozen_string_literal: true

require 'rubocop'
require 'securerandom'
require 'tmpdir'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Formatting < Base
          include Solargraph::Diagnostics::RubocopHelpers

          def process
            filename = uri_to_file(params['textDocument']['uri'])
            Dir.mktmpdir do |tempdir|
              tempfile = File.join(tempdir, File.basename(filename))
              rubocop_file = Diagnostics::RubocopHelpers.find_rubocop_file(filename)
              original = host.read_text(params['textDocument']['uri'])
              File.write tempfile, original
              begin
                args = ['-a', '-f', 'fi', tempfile]
                args.unshift('-c', fix_drive_letter(rubocop_file)) unless rubocop_file.nil?
                options, paths = RuboCop::Options.new.parse(args)
                store = RuboCop::ConfigStore.new
                redirect_stdout { RuboCop::Runner.new(options, store).run(paths) }
                result = File.read(tempfile)
                format original, result
              rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
                set_error(Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}")
              end
            end
          end

          private

          # @param original [String]
          # @param result [String]
          # @return [void]
          def format original, result
            ending = if original.end_with?("\n")
                       {
                         line: original.lines.length,
                         character: 0
                       }
                     elsif original.lines.empty?
                       {
                         line: 0,
                         character: 0
                       }
                     else
                       {
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
