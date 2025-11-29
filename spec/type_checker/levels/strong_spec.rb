describe Solargraph::TypeChecker do
  context 'strong level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strong)
    end

    it 'understands self type when passed as parameter' do
      checker = type_checker(%(
        class Location
          # @return [String]
          attr_reader :filename

          # @param other [self]
          def <=>(other)
            return nil unless other.is_a?(Location)

            filename <=> other.filename
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not misunderstand types during flow-sensitive typing' do
      checker = type_checker(%(
        class A
          # @param b [Hash{String => String}]
          # @return [void]
          def a b
            c = b["123"]
            return if c.nil?
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'respects pin visibility in if/nil? pattern' do
      checker = type_checker(%(
        class Foo
          # Get the namespace's type (Class or Module).
          #
          # @param bar [Symbol, nil]
          # @return [Symbol, Integer]
          def foo bar
            return 123 if bar.nil?
            bar
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'respects || overriding nilable types' do
      checker = type_checker(%(
        # @return [String]
        def global_config_path
          ENV['SOLARGRAPH_GLOBAL_CONFIG'] ||
              File.join(Dir.home, '.config', 'solargraph', 'config.yml')
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'is able to probe type over an assignment' do
      checker = type_checker(%(
        # @return [String]
        def global_config_path
          out = 'foo'
          out
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'respects pin visibility in if/foo pattern' do
      checker = type_checker(%(
        class Foo
          # Get the namespace's type (Class or Module).
          #
          # @param bar [Symbol, nil]
          # @return [Symbol, Integer]
          def foo bar
            baz = bar
            return baz if baz
            123
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'handles a flow sensitive typing if correctly' do
      checker = type_checker(%(
        # @param a [String, nil]
        # @return [void]
        def foo a = nil
          b = a
          if b
            b.upcase
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'handles another flow sensitive typing if correctly' do
      checker = type_checker(%(
        class A
          # @param e [String]
          # @param f [String]
          # @return [void]
          def d(e, f:); end

          # @return [void]
          def a
            c = rand ? nil : "foo"
            if c
              d(c, f: c)
            end
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'respects pin visibility' do
      checker = type_checker(%(
        class Foo
          # Get the namespace's type (Class or Module).
          #
          # @param baz [Integer, nil]
          # @return [Integer, nil]
          def foo baz = 123
            return nil if baz.nil?
            baz
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'provides nil checking on calls from parameters without assignments' do
      pending('https://github.com/castwide/solargraph/pull/1127')

      checker = type_checker(%(
        # @param baz [String, nil]
        #
        # @return [String]
        def quux(baz)
          baz.upcase # ERROR: Unresolved call to upcase on String, nil
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['#quux return type could not be inferred',
                                                     'Unresolved call to upcase on String, nil'])
    end

    it 'does not complain on array dereference' do
      checker = type_checker(%(
        # @param idx [Integer] an index
        # @param arr [Array<Integer>] an array of integers
        #
        # @return [void]
        def foo(idx, arr)
          arr[idx]
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'understands local evaluation with ||= removes nil from lhs type' do
      checker = type_checker(%(
        class Foo
          def initialize
            @bar = nil
          end

          # @return [Integer]
          def bar
            @bar ||= 123
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
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

    it 'understands complex use of self' do
      checker = type_checker(%(
        class A
          # @param other [self]
          #
          # @return [void]
          def foo other; end

          # @param other [self]
          #
          # @return [void]
          def bar(other); end
        end

        class B < A
          def bar(other)
            foo(other)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
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

    context 'with class name available in more than one gate' do
      let(:checker) do
        type_checker(%(
          module Foo
            module Bar
              class Symbol
              end
            end
          end

          module Foo
            module Baz
              class Quux
                # @return [void]
                def foo
                  objects_by_class(Bar::Symbol)
                end

                # @generic T
                # @param klass [Class<generic<T>>]
                # @return [Set<generic<T>>]
                def objects_by_class klass
                  # @type [Set<generic<T>>]
                  s = Set.new
                  s
                end
              end
            end
          end
        ))
      end

      it 'resolves class name correctly in generic resolution' do
        expect(checker.problems.map(&:message)).to be_empty
      end
    end

    it 'handles "while foo" flow sensitive typing correctly' do
      checker = type_checker(%(
        # @param a [String, nil]
        # @return [void]
        def foo a = nil
          b = a
          while b
              b.upcase
              b = nil if rand > 0.5
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does flow sensitive typing even inside a block' do
      checker = type_checker(%(
        class Quux
          # @param foo [String, nil]
          #
          # @return [void]
          def baz(foo)
            bar = foo
            [].each do
              bar.upcase unless bar.nil?
            end
          end
        end))

      expect(checker.problems.map(&:location).map(&:range).map(&:start)).to be_empty
    end

    it 'accepts ivar assignments and references with no intermediate calls as safe' do
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
      ))

      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'resolves self correctly in chained method calls' do
      checker = type_checker(%(
        class Foo
          # @param other [self]
          #
          # @return [Symbol, nil]
          def bar(other)
            # @type [Symbol, nil]
            baz(other)
          end

          # @param other [self]
          #
          # @sg-ignore Missing @return tag
          # @return [undefined]
          def baz(other); end
        end
      ))

      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'knows that ivar references with intermediate calls are not safe' do
      pending 'flow-sensitive typing improvements'

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

      expect(checker.problems.map(&:message)).to eq(["Foo#bar return type could not be inferred", "Unresolved call to round"])
    end

    it 'uses cast type instead of defined type' do
      checker = type_checker(%(
        # frozen_string_literal: true

        class Base; end

        class Subclass < Base
          # @return [String]
          attr_reader :bar
        end

        class Foo
          # @param bases [::Array<Base>]
          # @return [void]
          def baz(bases)
            # @param sub [Subclass]
            bases.each do |sub|
              puts sub.bar
            end
          end
        end
      ))

      # expect 'sub' to be treated as 'Subclass' inside the block, and
      # an error when trying to declare sub as Subclass
      expect(checker.problems.map(&:message)).not_to include('Unresolved call to bar on Base')
    end
  end
end
