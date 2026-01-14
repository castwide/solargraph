# frozen_string_literal: true

describe Solargraph::TypeChecker do
  context 'when at alpha level' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :alpha)
    end

    it 'reports use of superclass when subclass is required' do
      checker = type_checker(%(
        class Sup; end
        class Sub < Sup
          # @return [Sub]
          def foo
            Sup.new
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
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

    it 'accepts ivar assignments and references with no intermediate calls as safe' do
      pending 'flow sensitive typing improvements'

      checker = type_checker(%(
        class Foo
          def initialize
            # @type [Integer, nil]
            @foo = nil
          end

          # @return [void]
          def twiddle
            @foo = nil if rand if rand > 0.5
          end

          # @return [Integer]
          def bar
            @foo = 123
            out = @foo.round
            twiddle
            out
          end
        end
      ))

      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'knows that ivar references with intermediate calls are not safe' do
      checker = type_checker(%(
        class Foo
          def initialize
            # @type [Integer, nil]
            @foo = nil
          end

          # @return [void]
          def twiddle
            @foo = nil if rand if rand > 0.5
          end

          # @return [Integer]
          def bar
            @foo = 123
            twiddle
            @foo.round
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq(["Foo#bar return type could not be inferred", "Unresolved call to round on Integer, nil"])
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
