# frozen_string_literal: true

module Solargraph
  module Convention
    class Gemspec < Base
      def local source_map
        return Convention::Base::EMPTY_ENVIRON if source_map.filename.nil?
        # @sg-ignore https://github.com/castwide/solargraph/pull/1258
        return Convention::Base::EMPTY_ENVIRON unless File.basename(source_map.filename).end_with?('.gemspec')
        @local ||= Environ.new(
          requires: ['rubygems'],
          pins: [
            Solargraph::Pin::Reference::Override.from_comment(
              'Gem::Specification.new',
              %(
@yieldparam [self]
              ),
              source: :gemspec
            )
          ]
        )
      end
    end
  end
end
