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

    it 'ignores tagged return types with empty method bodies' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          def bar; end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores mismatched return tags' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          def bar
            'string'
          end
        end
      ))
      expect(checker.problems).to be_empty
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

    it 'ignores mismatched inherited return tags' do
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
      expect(checker.problems).to be_empty
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
      expect(checker.problems.first.message).to include('Unresolved type')
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

    it 'reports unresolved return tags in root namespace' do
      checker = type_checker(%(
        # @return [UnknownClass]
        def bar; end
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

    it 'ignores mismatched type tags' do
      checker = type_checker(%(
        # @type [Integer]
        x = 'string'
      ))
      expect(checker.problems).to be_empty
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
      # @todo This test uses kramdown-parser-gfm because it's a gem dependency known to
      #   lack typed methods. A better test wouldn't depend on the state of
      #   vendored code.
      gemspec = Gem::Specification.find_by_name('kramdown-parser-gfm')
      pins = Solargraph::GemPins.build(gemspec)
      Solargraph::Cache.save('gems', "#{gemspec.name}-#{gemspec.version}.ser", pins)  
      checker = type_checker(%(
        require 'kramdown-parser-gfm'
        # @type [String]
        doc = Kramdown::Parser::GFM.new(nil, nil).parse
      ))
      expect(checker.problems).to be_empty
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

    it 'validates param duck types' do
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

    it 'validates return duck types' do
      checker = type_checker(%(
        class Foo
          # @return [#to_s]
          def bar; end
        end
      ))
      expect(checker.problems).to be_empty
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

    it 'validates tagged kwoptarg params' do
      checker = type_checker(%(
        class Foo
          # @param foo [String]
          def bar(foo: ''); end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates tagged kwarg params' do
      checker = type_checker(%(
        class Foo
          # @param foo [String]
          def bar(foo:); end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates untagged restarg params' do
      checker = type_checker(%(
        class Foo
          def bar(*args); end
        end
      ))
      expect(checker.problems).to be_empty
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

    it 'ignores blocks with parameters' do
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

    it 'ignores mismatched boolean return types' do
      checker = type_checker(%(
        class Foo
          # @return [Boolean]
          def bar
            'true'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'qualifies param tags in declaration context' do
      checker = type_checker(%(
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
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores untagged parameters' do
      checker = type_checker(%(
        class Foo
          def bar(baz); end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports too many arguments' do
      checker = type_checker(%(
        def foo; end
        foo(1)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Too many arguments')
    end

    it 'reports not enough arguments' do
      checker = type_checker(%(
        def foo(bar); end
        foo()
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Not enough arguments')
    end

    it 'ignores three dots' do
      checker = type_checker(%(
        class Foo
          def initialize(arg); end
        end
        class Bar < Foo
          def initialize(...)
            super
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts kwargs with explicit blockargs' do
      checker = type_checker(%(
        def foo(bar:, &block); end
        foo(bar: 'bar', &block)
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts kwargs with implicit blockargs' do
      checker = type_checker(%(
        def foo(bar:); end
        foo(bar: 'bar', &block)
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores restarg arguments' do
      checker = type_checker(%(
        def foo(*bar); end
        foo(1, 2, 3)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports missing required keyword arguments' do
      checker = type_checker(%(
        def foo(bar:); end
        foo()
      ))
      expect(checker.problems).to be_one
    end

    it 'ignores calls sent as keyword arguments' do
      checker = type_checker(%(
        def foo(one: '', two: ''); end
        hash = {one: 'one', two: 'two'}
        foo(hash)
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates restarg arguments with optional kw parameters' do
      checker = type_checker(%(
        def foo(*bar, baz: true); end
        foo(1, 2, 3)
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates optional argument arity' do
      checker = type_checker(%(
        def foo(bar, baz, quz = true); end
        foo(1, 2, 3)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports too many optional arguments' do
      checker = type_checker(%(
        def foo(bar, baz, quz = true); end
        foo(1, 2, 3, 4)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Too many arguments')
    end

    it 'reports arity problems for core methods' do
      checker = type_checker(%(
        File.atime()
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Not enough arguments')
    end

    it 'checks overloads for valid arity' do
      checker = type_checker(%[
        class Foo
          # @overload bar(one, two)
          def bar
          end
        end

        Foo.new.bar(1, 2)
      ])
      expect(checker.problems).to be_empty
    end

    it 'assumes restarg for `args` parameters in core' do
      checker = type_checker(%(
        File.join('foo', 'bar')
      ))
      expect(checker.problems).to be_empty
    end

    it 'verifies block passes in arguments' do
      checker = Solargraph::TypeChecker.load_string(%(
        class Foo
          def map(&block)
            block.call(100)
          end

          def to_s
            map(&:to_s)
          end
        end
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end

    it 'verifies args and block passes' do
      checker = Solargraph::TypeChecker.load_string(%(
        class Foo
          def map(x, &block)
            block.call(x)
          end

          def to_s
            map(x, &:to_s)
          end
        end
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end

    it 'verifies extra block passes in chained calls' do
      checker = Solargraph::TypeChecker.load_string(%(
        ''.to_s(&:nil?)
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end

    it 'verifies extra block variables in calls with args' do
      checker = Solargraph::TypeChecker.load_string(%(
        def foo(bar); end
        foo(1, &block)
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end

    it 'verifies splats passed to arguments' do
      checker = Solargraph::TypeChecker.load_string(%(
        def foo(bar, baz); end
        foo(*splat)
      ), 'test.rb')
      expect(checker.problems).to be_empty
    end

    it 'verifies arity of chained super calls' do
      checker = type_checker(%(
        class Foo
          def something arg
          end
        end
        class Bar < Foo
          def something
            super(1) + 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports invalid arity of chained super calls' do
      checker = type_checker(%(
        class Foo
          def something
          end
        end
        class Bar < Foo
          def something
            super(1) + 2
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Too many arguments')
    end

    it 'verifies arity of chained zsuper calls' do
      checker = type_checker(%(
        class Foo
          def something arg
          end
        end
        class Bar < Foo
          def something arg
            super + 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'verifies arity of chained zsuper calls with restargs' do
      checker = type_checker(%(
        class Foo
          def something arg1, arg2
          end
        end
        class Bar < Foo
          def something *arg
            super + 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'verifies arity of chained zsuper calls with kwargs' do
      checker = type_checker(%(
        class Foo
          def something arg1, arg2:
          end
        end
        class Bar < Foo
          def something *arg
            super + 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports invalid arity of chained zsuper calls' do
      checker = type_checker(%(
        class Foo
          def something arg
          end
        end
        class Bar < Foo
          def something
            super + 2
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Not enough arguments')
    end

    it 'verifies splatted kwargs' do
      checker = type_checker(%(
        def xxx(from:, to:); end
        xxx(**{from: 1, to: 2})
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports splatted kwargs with missing arguments' do
      checker = type_checker(%(
        def xxx(from:, to:); end
        xxx(**{from: 1})
      ))
      expect(checker.problems).to be_one
    end

    it 'ignores splatted kwargs' do
      checker = type_checker(%(
        def xxx(from:, to:); end
        params = {from: 1, to: 2}
        xxx(**params)
      ))
      expect(checker.problems).to be_empty
    end

    it 'recognizes splatted kwargs' do
      checker = type_checker(%(
        def xxx(from: nil, to: nil)
        end

        params = {from: 1, to: 2}

        xxx(**params)
      ))
      expect(checker.problems).to be_empty
    end

    it 'differentiates local variables from methods' do
      checker = type_checker(%(
        class Example
          def foo(bar)
            'lol'
          end
          def baz
            [].each do |foo|
              foo.bar
            end
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'allows Kernel#raise without arguments' do
      # This is necessary because the core docs erroneously define the
      # signature as `Kernel#raise(*, _)`
      # See https://github.com/castwide/solargraph/issues/418
      checker = type_checker(%(
        raise
      ))
      expect(checker.problems).to be_empty
    end

    it 'handles mixed splats' do
      checker = type_checker(%(
        class Foo
          def self.make(arg, *args, **kwargs)
            new([1, 2], *args, **kwargs)
          end

          def initialize(timeframe, scope = nil, now: Time.now)
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'handles kwrestargs passed to methods without kwsplats' do
      checker = type_checker(%(
        def foo(arg1:, arg2:, arg3:, arg4: false)
        end

        foo(
          arg1: val1,
          arg2: val2,
          **kwparams
        )
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates constant aliases for namespaces' do
      checker = type_checker(%(
        class Foo; end
        Bar = Foo

        # @return [Bar]
        def foo
          Bar
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts anonymous splats for instance methods' do
      checker = type_checker(%(
        def foo(*); end
        foo('bar')
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts anonymous splats for class methods' do
      checker = type_checker(%(
        class Foo
          def self.foo(*); end
        end
        Foo.foo('bar')
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts Hash#[] calls for generic Hash types' do
      checker = type_checker(%(
        # @type [Hash{String => String}]
        x = {}
        x['arg']
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts namespace aliases for return tags' do
      checker = type_checker(%(
        # @return [Thread::Mutex]
        def get_a_mutex; end
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts namespace aliases for type tags' do
      checker = type_checker(%(
        # @type [Thread::Mutex]
        x = get_a_mutex
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts namespace aliases from nested namespaces' do
      checker = type_checker(%(
        class Foo
          # @return [Thread::Mutex]
          def get_a_mutex; end
        end
      ))
      expect(checker.problems).to be_empty
    end
  end
end
