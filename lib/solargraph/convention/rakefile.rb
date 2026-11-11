# frozen_string_literal: true

module Solargraph
  module Convention
    class Rakefile < Base
      def local source_map
        return EMPTY_ENVIRON if source_map.filename.nil?
        # @sg-ignore https://github.com/castwide/solargraph/pull/1258
        basename = File.basename(source_map.filename)
        return EMPTY_ENVIRON unless basename.end_with?('.rake') || basename == 'Rakefile'

        @local ||= Environ.new(
          requires: ['rake'],
          domains: ['Rake::DSL']
        )
      end
    end
  end
end
