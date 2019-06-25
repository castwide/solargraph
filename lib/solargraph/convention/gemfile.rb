# frozen_string_literal: true

module Solargraph
  module Convention
    class Gemfile < Base
      def match? source
        File.basename(source.filename) == 'Gemfile'
      end

      def environ
        @environ ||= Environ.new(
          requires: ['bundler'],
          domains: ['Bundler::Dsl']
        )
      end
    end
  end
end
