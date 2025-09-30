describe Solargraph::TypeChecker do
  context 'strong level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strong)
    end

    it 'does not complain on array dereference' do
      checker = type_checker(%(
        # @param idx [Integer, nil] an index
        # @param arr [Array<Integer>] an array of integers
        #
        # @return [void]
        def foo(idx, arr)
          arr[idx]
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'complains on bad @type assignment' do
      checker = type_checker(%(
        # @type [Integer]
        c = Class.new
      ))
      expect(checker.problems.map(&:message))
        .to eq ['Declared type Integer does not match inferred type Class for variable c']
    end

    it 'does not complain on another variant of Class.new' do
      checker = type_checker(%(
        class Class
          # @return [self]
          def self.blah
            new
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not complain on indirect Class.new', skip: 'hangs in a loop currently' do
      checker = type_checker(%(
        class Foo < Class; end
        Foo.new
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'reports unneeded @sg-ignore tags' do
      checker = type_checker(%(
        class Foo
          # @sg-ignore
          # @return [void]
          def bar; end
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unneeded @sg-ignore comment'])
    end

    it 'reports missing return tags' do
      checker = type_checker(%(
        class Foo
          def bar; end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @return tag')
    end

    it 'ignores nilable type issues' do
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
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'calls out keyword issues even when required arg count matches' do
      checker = type_checker(%(
        # @param a [String]
        # @param b [String]
        # @return [void]
        def foo(a = 'foo', b:); end

        # @return [void]
        def bar
         foo('baz')
        end
      ))
      expect(checker.problems.map(&:message)).to include('Call to #foo is missing keyword argument b')
    end

    it 'calls out type issues even when keyword issues are there' do
      pending('fixes to arg vs param checking algorithm')

      checker = type_checker(%(
        # @param a [String]
        # @param b [String]
        # @return [void]
        def foo(a = 'foo', b:); end

        # @return [void]
        def bar
         foo(123)
        end
      ))
      expect(checker.problems.map(&:message))
        .to include('Wrong argument type for #foo: a expected String, received 123')
    end

    it 'calls out keyword issues even when arg type issues are there' do
      checker = type_checker(%(
        # @param a [String]
        # @param b [String]
        # @return [void]
        def foo(a = 'foo', b:); end

        # @return [void]
        def bar
         foo(123)
        end
      ))
      expect(checker.problems.map(&:message)).to include('Call to #foo is missing keyword argument b')
    end

    it 'reports missing param tags' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar baz
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @param tag')
    end

    it 'reports missing param and return tags on writers when instance variable type not defined' do
      checker = type_checker(%(
        class Foo
          attr_writer :bar
        end
      ))
      expect(checker.problems.map(&:message)).to include('Missing @param tag for value on Foo#bar=')
      expect(checker.problems.map(&:message)).to include('Missing @return tag for Foo#bar=')
    end

    it 'reports missing return tags on readers when instance variable type not defined' do
      checker = type_checker(%(
        class Foo
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @return tag')
    end

    it 'ignores missing return tags on readers when instance variable type not defined' do
      checker = type_checker(%(
        class Foo
          # @param bar [String]
          def initialize(bar)
            @bar = bar
          end

          attr_reader :bar
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'ignores missing param and return tags on writers when instance variable type defined' do
      checker = type_checker(%(

        class Foo
          # @param bar [String]
          def initialize(bar)
            @bar = bar
          end

          attr_writer :bar
        end
        class Bar
          # @param baz [String]
          def initialize(baz)
            @baz = baz
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'reports missing kwoptarg param tags' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar(baz: 0); end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @param tag')
    end

    it 'ignores optional params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar *args
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores optional keyword params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar **opts
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores untagged block params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar &block
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'does not need fully specified container types' do
      checker = type_checker(%(
        class Foo
          # @param foo [Array<String>]
          # @return [void]
          def bar foo: []; end

          # @param bing [Array]
          # @return [void]
          def baz(bing)
            bar(foo: bing)
            generic_values = [1,2,3].map(&:to_s)
            bar(foo: generic_values)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'treats a parameter type of undefined as not provided' do
      checker = type_checker(%(
        class Foo
          # @param foo [Array<String>]
          # @return [void]
          def bar foo: []; end

          # @param bing [Array<undefind>]
          # @return [void]
          def baz(bing)
            bar(foo: bing)
            generic_values = [1,2,3].map(&:to_s)
            bar(foo: generic_values)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'ignores generic resolution failure with no generic tag' do
      checker = type_checker(%(
        class Foo
          # @param foo [Class<String>]
          # @return [void]
          def bar foo:; end

          # @param bing [Class<generic<T>>]
          # @return [void]
          def baz(bing)
            bar(foo: bing)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'ignores undefined resolution failures' do
      checker = type_checker(%(
        class Foo
          # @generic T
          # @param klass [Class<undefined>>]
          # @return [Set<generic<T>>]
          def pins_by_class klass; [].to_set; end
        end
        class Bar
          # @return [Enumerable<Integer>]
          def block_pins
            foo = Foo.new
            foo.pins_by_class(Integer)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'ignores generic resolution failures from current Solargraph limitation' do
      checker = type_checker(%(
        class Foo
          # @generic T
          # @param klass [Class<generic<T>>]
          # @return [Set<generic<T>>]
          def pins_by_class klass; [].to_set; end
        end
        class Bar
          # @return [Enumerable<Integer>]
          def block_pins
            foo = Foo.new
            foo.pins_by_class(Integer)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'ignores generic resolution failures with only one arg' do
      checker = type_checker(%(
        # @generic T
        # @param path [String]
        # @param klass [Class<generic<T>>]
        # @return [void]
        def code_object_at path, klass = Integer
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not complain on select { is_a? } pattern' do
      checker = type_checker(%(
        # @param arr [Enumerable<Object>}
        # @return [Enumerable<Integer>]
        def downcast_arr(arr)
          arr.select { |pin| pin.is_a?(Integer) }
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not complain on adding nil to types via return value' do
      checker = type_checker(%(
        # @param bar [Integer]
        # @return [Integer, nil]
        def foo(bar)
          bar
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not complain on adding nil to types via select' do
      checker = type_checker(%(
        # @return [Float, nil]}
        def bar; rand; end

        # @param arr [Enumerable<Object>}
        # @return [Integer, nil]
        def downcast_arr(arr)
          # @type [Object, nil]
          foo = arr.select { |pin| pin.is_a?(Integer) && bar }.last
          foo
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'inherits param tags from superclass methods' do
      checker = type_checker(%(
        class Foo
          # @param arg [Integer]
          # @return [void]
          def meth arg
          end
        end

        class Bar < Foo
          def meth arg
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'resolves constants inside modules inside classes' do
      checker = type_checker(%(
        class Bar
          module Foo
            CONSTANT = 'hi'
          end
        end

        class Bar
          include Foo

          # @return [String]
          def baz
            CONSTANT
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'understands Open3 methods' do
      checker = type_checker(%(
        require 'open3'

        # @return [void]
        def run_command
          # @type [Hash{String => String}]
          foo = {'foo' => 'bar'}
          Open3.capture2e(foo, 'ls', chdir: '/tmp')
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end
  end
end
