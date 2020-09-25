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

          class BlankRubocopFormatter < ::RuboCop::Formatter::BaseFormatter; end

          def process
            file_uri = params['textDocument']['uri']
            config = host.formatter_config(file_uri)
            original = host.read_text(file_uri)
            args = cli_args(file_uri, config)

            options, paths = RuboCop::Options.new.parse(args)
            options[:stdin] = original
            redirect_stdout do
              RuboCop::Runner.new(options, RuboCop::ConfigStore.new).run(paths)
            end
            result = options[:stdin]

            format original, result
          rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
            set_error(Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}")
          end

          private

          def cli_args file, config
            [
              config['cops'] == 'all' ? '--auto-correct-all' : '--auto-correct',
              '--cache', 'false',
              '--format', 'Solargraph::LanguageServer::Message::' \
                          'TextDocument::Formatting::BlankRubocopFormatter',
              config['extra_args'],
              file
            ].flatten
          end

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
