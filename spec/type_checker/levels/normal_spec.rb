describe Solargraph::TypeChecker do
  context 'normal level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :normal)
    end

    it 'ignores missing return tags' do
      checker = type_checker(%(
        class Foo
          def bar; end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores void return tags' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar
            'string'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates existing return tags' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          def bar
            'string'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched return tags' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          def bar
            'string'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'ignores undefined inferred return types' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          def bar
            unknown_method
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates inherited return tags' do
      checker = type_checker(%(
        class Sup
          # @return [String]
          def name
            'sup'
          end
        end

        class Sub < Sup
          def name
            'sub'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates inherited return tags from mixins' do
      checker = type_checker(%(
        module Mixin
          # @return [String]
          def name
            'sup'
          end
        end

        class Thing
          include Mixin

          def name
            'sub'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched inherited return tags' do
      checker = type_checker(%(
        class Sup
          # @return [String]
          def name
            'sup'
          end
        end

        class Sub < Sup
          def name
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'reports mismatched return tags from mixins' do
      checker = type_checker(%(
        module Mixin
          # @return [String]
          def name
            'sup'
          end
        end

        class Thing
          include Mixin

          def name
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'resolves param tags' do
      checker = type_checker(%(
        class Foo
          # @param arg [String]
          def bar arg
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unresolved param tags' do
      checker = type_checker(%(
        class Foo
          # @param arg [UnknownClass]
          def bar arg
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved')
    end

    it 'ignores variables without type tags' do
      checker = type_checker(%(
        x = foo
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unresolved return tags' do
      checker = type_checker(%(
        class Foo
          # @return [UnknownClass]
          def bar; end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved')
    end

    it 'validates existing type tags' do
      checker = type_checker(%(
        # @type [Integer]
        x = 100
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched type tags' do
      checker = type_checker(%(
        # @type [Integer]
        x = 'string'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'ignores undefined inferred variable types' do
      checker = type_checker(%(
        # @type [Integer]
        x = unknown_method
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unresolved return tags' do
      checker = type_checker(%(
        # @type [UnknownClass]
        x = unknown_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved')
    end

    it 'ignores unresolved method calls' do
      checker = type_checker(%(
        unknown_method.another_unknown_method
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores variable types with undefined inferences from external sources' do
      # @todo This test uses Nokogiri because it's a gem dependency known to
      #   lack typed methods. A better test wouldn't depend on the state of
      #   vendored code.
      checker = type_checker(%(
        require 'nokogiri'
        # @type [Nokogiri::HTML::Document]
        doc = Nokogiri::HTML.parse('something')
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

    it 'ignores undefined argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz); end
        end
        Foo.new.bar(unknown_method)
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores untyped attributes' do
      checker = type_checker(%(
        class Foo
          attr_accessor :bar
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts one of several param types' do
      checker = type_checker(%(
        class Foo
          # @param baz [String, Integer]
          def bar baz
          end
        end
        Foo.new.bar('string')
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates keyword params' do
      # @todo Skip for legacy Ruby
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          def bar baz:
          end
        end
        Foo.new.bar baz: 'string'
      ))
      expect(checker.problems).to be_empty
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

    it 'validates optional keyword params' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: 'string'
      ))
      expect(checker.problems).to be_empty
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

    it 'validates mixed arguments and kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz, quz: ''
          end
        end
        Foo.new.bar 'one', quz: 'two'
        Foo.new.bar 'one'
      ))
      expect(checker.problems).to be_empty
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

    it 'validates multiple optional kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz: '', quz: ''
          end
        end
        Foo.new.bar quz: 'string'
      ))
      expect(checker.problems).to be_empty
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

    it 'ignores untagged kwarg params' do
      checker = type_checker(%(
        class Foo
          # @param quz [String]
          def bar baz: '', quz: ''
          end
        end
        Foo.new.bar baz: 100, quz: ''
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates duck types' do
      checker = type_checker(%(
        class Foo
          # @param baz [#to_s]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: String.new
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

    it 'validates untagged kwrestargs' do
      checker = type_checker(%(
        class Foo
          def bar **baz
          end
        end
        Foo.new.bar one: 'one', two: 2
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates tagged kwrestargs' do
      checker = type_checker(%(
        class Foo
          # @param one [String]
          # @param two [Integer]
          def bar **baz
          end
        end
        Foo.new.bar one: 'one', two: 2
      ))
      expect(checker.problems).to be_empty
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

    it 'ignores undocumented blocks' do
      checker = type_checker(%(
        class Foo
          def bar
            yield if block_given?
          end
        end
        Foo.new.bar do
          puts 'block'
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores parameterized blocks' do
      checker = type_checker(%(
        class Foo
          def bar &block
          end
        end
        Foo.new.bar do
          puts 'block'
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores trailing optional hash parameters without tags' do
      checker = type_checker(%(
        class Foo
          def bar opts = {}
          end
        end
        Foo.new.bar one: 'one', two: 'two'
      ))
      expect(checker.problems).to be_empty
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

    it 'validates boolean return types' do
      checker = type_checker(%(
        class Foo
          # @return [Boolean]
          def bar
            1 == 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched boolean return types' do
      checker = type_checker(%(
        class Foo
          # @return [Boolean]
          def bar
            'true'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'qualifies param tags in declaration context' do
      checker = Solargraph::TypeChecker.load_string(%(
        module Container
          class First
          end

          class Second
            # @param one [First]
            def self.take one
            end
          end
        end

        first = Container::First.new
        Container::Second.take first
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end
  end
end
