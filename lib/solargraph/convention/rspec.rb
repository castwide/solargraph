# frozen_string_literal: true

module Solargraph
  module Convention
    class Rspec < Base
      def match? source
        File.basename(source.filename) =~ /_spec\.rb$/
      end

      def environ
        @environ ||= Environ.new(
          requires: ['rspec'],
          domains: ['RSpec::Matchers', 'RSpec::ExpectationGroups'],
          # This override is necessary due to an erroneous @return tag in
          # rspec's YARD documentation.
          overrides: [
            Solargraph::Pin::Reference::Override.method_return('RSpec::Matchers#expect', 'RSpec::Expectations::ExpectationTarget')
          ]
        )
      end
    end
  end
end
