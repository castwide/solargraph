# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Definition < Base
          def process
            @line = params['position']['line']
            @column = params['position']['character']
            set_result(code_location || require_location || [])
          end

          private

          # @return [Array<Hash>, nil]
          def code_location
            suggestions = host.definitions_at(params['textDocument']['uri'], @line, @column) || []
            return nil if suggestions.empty?
            suggestions.map do |pin|
              loc = pin.best_location
              next if loc.nil? || loc.filename.nil?

              {
                uri: file_to_uri(loc.filename),
                range: loc.range.to_hash
              }
            end.compact
          end

          # @return [Array<Hash>, nil]
          def require_location
            # @todo Terrible hack - move this logic to [Solargraph::Source::Chain::Parameter]
            #   @example
            #     require 'click_me'
            #             ^^^^^^^^^^
            lib = host.library_for(params['textDocument']['uri'])
            rloc = Solargraph::Location.new(uri_to_file(params['textDocument']['uri']),
                                            Solargraph::Range.from_to(@line, @column, @line, @column))
            dloc = lib.locate_ref(rloc)
            return nil if dloc.nil?
            [
              {
                uri: file_to_uri(dloc.filename),
                range: dloc.range.to_hash
              }
            ]
          end
        end
      end
    end
  end
end
