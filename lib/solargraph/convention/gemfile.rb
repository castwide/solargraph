# frozen_string_literal: true

module Solargraph
  module Convention
    class Gemfile < Base
      def local source_map
        return EMPTY_ENVIRON if source_map.filename.nil?
        # @sg-ignore https://github.com/castwide/solargraph/pull/1258
        # SourceMap#filename should be markable as pure via inline RBS, so
        # this guard narrows the repeated call.
        return EMPTY_ENVIRON unless File.basename(source_map.filename) == 'Gemfile'
        @local ||= Environ.new(
          requires: ['bundler'],
          domains: ['Bundler::Dsl']
        )
      end
    end
  end
end
