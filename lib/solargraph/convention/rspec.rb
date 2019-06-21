module Solargraph
  module Convention
    class Rspec < Base
      def match? source
        File.basename(source.filename) =~ /_spec\.rb$/
      end

      def environ
        Environ.new(
          requires: ['rspec'],
          domains: ['RSpec::Matchers', 'RSpec::ExpectationGroups']
        )
      end
    end
  end
end
