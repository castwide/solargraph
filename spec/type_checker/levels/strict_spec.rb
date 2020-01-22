describe Solargraph::TypeChecker do
  context 'strict level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strict)
    end

    it 'ignores method calls with inferred types' do
      checker = type_checker(%(
        String.new.upcase
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports method calls without inferred types' do
      checker = type_checker(%(
        unknown_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call')
    end

    it 'reports undefined method calls with defined roots' do
      checker = type_checker(%(
        String.new.not_a_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call')
      expect(checker.problems.first.message).to include('not_a_method')
    end

    it 'ignores undefined method calls from external sources' do
      # @todo This test uses Nokogiri because it's a gem dependency known to
      #   lack typed methods. A better test wouldn't depend on the state of
      #   vendored code.
      checker = type_checker(%(
        require 'nokogiri'
        Nokogiri::HTML.parse('code').undefined_call
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates existing param tags' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'ignores missing optional arguments' do
      checker = type_checker(%(
        class Foo
          def bar *baz
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz); end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports missing keyword params' do
      # @todo Skip for legacy Ruby
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          def bar baz:
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('missing keyword argument')
    end

    it 'reports mismatched keyword arguments' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: 100
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports argument mismatches in mixed arguments and kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz, quz: ''
          end
        end
        Foo.new.bar 1, quz: 'two'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('baz')
    end

    it 'reports mismatches in multiple kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz: '', quz: ''
          end
        end
        Foo.new.bar quz: 100
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('quz')
    end

    it 'reports mismatched duck types' do
      checker = type_checker(%(
        class Foo
          # @param baz [#unknown_method]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: String.new
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports mismatched kwrestargs' do
      checker = type_checker(%(
        class Foo
          # @param one [String]
          # @param two [Integer]
          def bar **baz
          end
        end
        Foo.new.bar one: 'one', two: 'two'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('two')
    end

    it 'reports mismatched params in trailing optional hash parameters' do
      checker = type_checker(%(
        class Foo
          # @param named [String]
          def bar opts = {}
          end
        end
        Foo.new.bar named: 0
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('named')
    end
  end
end
