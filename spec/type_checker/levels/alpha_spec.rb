# frozen_string_literal: true

describe Solargraph::TypeChecker do
  context 'when at alpha level' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :alpha)
    end

    it 'allows a compatible function call from two distinct types in a union' do
      checker = type_checker(%(
        class Foo
          # @param baz [::Boolean, nil]
          # @return [void]
          def bar(baz: nil)
            baz.nil?
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not falsely enforce nil in return types' do
      checker = type_checker(%(
      # @return [Integer]
      def foo
        # @sg-ignore
        # @type [Integer, nil]
        a = bar
        a || 123
      end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'reports nilable type issues' do
      checker = type_checker(%(
        # @param a [String]
        # @return [void]
        def foo(a); end

        # @param b [String, nil]
        # @return [void]
        def bar(b)
          foo(b)
        end
      ))
      expect(checker.problems.map(&:message))
        .to eq(['Wrong argument type for #foo: a expected String, received String, nil'])
    end

    it 'tracks type of ivar' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def initialize
            @sync_count = 0
          end

          # @return [void]
          def synchronized?
            @sync_count < 2
          end

          # @return [void]
          def catalog
            @sync_count += 1
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'understands &. in return position' do
      checker = type_checker(%(
        class Baz
          # @param bar [String, nil]
          # @return [String]
          def foo bar
            bar&.upcase || 'undefined'
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'can infer types based on || and &&' do
      checker = type_checker(%(
        class Baz
          # @param bar [String, nil]
          # @return [Boolean, String]
          def foo bar
            !bar || bar.upcase
          end

          # @param bar [String, nil]
          # @return [String, nil]
          def bing bar
            bar && bar.upcase
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end
  end
end
