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

    it 'validates arguments that match duck type params' do
      checker = type_checker(%(
        class Foo
          # @param baz [#to_s]
          # @return [void]
          def bar(baz); end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
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

    it 'reports untyped methods without inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            unknown_method
          end
        end
      ))
      expect(checker.problems.length).to eq(2)
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'ignores untyped methods with inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            Array.new
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'skips type inference for method macros' do
      checker = type_checker(%(
        # @!method bar
        #   @return [String]
        class Foo; end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports untyped attributes' do
      checker = type_checker(%(
        class Foo
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_one
      # @todo Maybe change the message to "missing @return tag"
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'validates attr_writer parameters' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          attr_accessor :bar
        end
        Foo.new.bar = 'hello'
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports invalid attr_writer parameters' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          attr_accessor :bar
        end
        Foo.new.bar = 'hello'
      ))
      expect(checker.problems).to be_one
    end

    it 'reports arguments that do not match duck type params' do
      checker = type_checker(%(
        class Foo
          # @param baz [#upcase]
          # @return [void]
          def bar(baz); end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'validates complex parameters' do
      checker = type_checker(%(
        class Foo
          # @param baz [Hash, Array]
          # @return [void]
          def bar baz
          end
        end
        Foo.new.bar([1, 2])
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports arguments that do not match complex parameters' do
      checker = type_checker(%(
        class Foo
          # @param baz [Hash, Array]
          def bar baz
          end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    # @todo Should this be tested at the strong level?
    it 'validates Hash#[]= with simple objects' do
      checker = type_checker(%(
        h = {}
        h['foo'] = 'bar'
        h[100] = []
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports incorrect arguments from superclass param tags' do
      checker = type_checker(%(
        class Foo
          # @param arg [String]
          def meth arg
          end
        end

        class Bar < Foo
          def meth arg
          end
        end

        # Error: arg should be a String
        Bar.new.meth(100)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'validates Boolean parameters' do
      checker = type_checker(%(
        class Foo
          # @param bool [Boolean]
          def bar bool
          end
        end

        Foo.new.bar(true)
        Foo.new.bar(false)
      ))
      expect(checker.problems).to be_empty
    end

    it 'invalidates incorrect Boolean parameters' do
      checker = type_checker(%(
        class Foo
          # @param bool [Boolean]
          def bar bool
          end
        end

        Foo.new.bar(1)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'resolves Kernel methods in instance scopes' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar
            raise 'oops'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports missing arguments' do
      checker = type_checker(%(
        class Foo
          def bar(baz)
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Not enough arguments')
    end
  end
end
