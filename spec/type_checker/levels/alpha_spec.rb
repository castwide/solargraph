# frozen_string_literal: true

describe Solargraph::TypeChecker do
  context 'when at alpha level' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :alpha)
    end

    it 'resolves self correctly in arguments' do
      checker = type_checker(%(
        class Foo
          # @param other [self]
          #
          # @return [String]
          def bar other
            other.bing
          end

          # @return [String]
          def bing
            'bing'
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'resolves self correctly in arguments (second case)' do
      checker = type_checker(%(
        class Blah
          # @return [String]
          attr_reader :filename

          # @param filename [String]
          def initialize filename
            @filename = filename
          end

          # @param location [self]
          def contain? location
            filename == location.filename
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end
  end
end
