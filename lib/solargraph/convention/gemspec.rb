module Solargraph
  module Convention
    class Gemspec < Base
      def match? source
        File.basename(source.filename).end_with?('.gemspec')
      end

      def environ
        @environ ||= Environ.new(
          requires: ['rubygems'],
          overrides: [
            Solargraph::Pin::Reference::Override.from_comment(
              'Gem::Specification.new',
              %(
@yieldparam [self]
              )
            )
          ]
        )
      end
    end
  end
end
