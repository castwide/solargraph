# frozen_string_literal: true

describe Solargraph::TypeChecker do
  context 'with level set to strong' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strong)
    end

    it 'requires strict return tags for attributes when nil is involved' do
      checker = type_checker(%(
        class Foo
          # @param bar [String, nil]
          def initialize(bar = nil)
            @bar = bar
          end

          # The tag is [String] but @bar can be nil per the constructor
          #
          # @return [String]
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'does not flag attributes whose declared type already allows nil' do
      checker = type_checker(%(
        class Foo
          # @param bar [String, nil]
          def initialize(bar = nil)
            @bar = bar
          end

          # @return [String, nil]
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'requires strict return tags when nil is involved and used second in a ternary' do
      checker = type_checker(%(
        class Foo
          # The tag is [String] but the inference is [String, nil]
          #
          # @return [String]
          def bar
            false ? 'bar' : nil
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'requires strict return tags when nil is involved and used first in a ternary' do
      checker = type_checker(%(
        class Foo
          # The tag is [String] but the inference is [String, nil]
          #
          # @return [String]
          def bar
            true ? nil : 'bar'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'understands self type when passed as parameter' do
      checker = type_checker(%(
        class Location
          # @return [String]
          attr_reader :filename

          # @param other [self]
          # @return [-1, 0, 1, nil]
          def <=>(other)
            return nil unless other.is_a?(Location)

            filename <=> other.filename
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'does not misunderstand types during flow sensitive typing' do
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

    it 'calls out missing args after a defaulted param' do
      checker = type_checker(%(
        # @param a [String]
        # @param b [String]
        # @return [void]
        def foo(a = 'foo', b); end

        # @return [void]
        def bar
         foo(123)
        end
      ))
      expect(checker.problems.map(&:message)).to include('Not enough arguments to #foo')
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

      expect(checker.problems.map(&:message)).to eq(['Foo#bar return type could not be inferred',
                                                     'Unresolved call to round on Integer, nil'])
    end

    it 'performs simple flow-sensitive typing on lvars' do
      checker = type_checker(%(
        class Foo
          # @param bar [Integer, nil]
          # @return [::Boolean, ::Integer]
          def foo bar
            !bar || bar.abs
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'performs simple flow-sensitive typing on ivars' do
      checker = type_checker(%(
        class Foo
          # @param bar [::Integer, nil]
          def initialize bar: nil
            @bar = bar
          end

          # @return [::Boolean, ::Integer]
          def foo
            !@bar || @bar.abs
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'performs complex flow-sensitive typing on ivars' do
      checker = type_checker(%(
        class Foo
          # @param bar [::Array<Integer>, nil]
          def initialize bar: nil
            @bar = bar
          end

          def maybe_bar?
            return !@bar.empty? if defined?(@bar) && @bar
            false
          end
        end
      ))

      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'updates a parameter type after reassignment to a different non-literal type' do
      checker = type_checker(%(
        class Position
          # @return [Integer]
          def line
            1
          end
        end

        module PositionNormalizer
          # @param position [Position, Array(Integer, Integer)]
          # @return [Position]
          def self.normalize(position)
            Position.new
          end
        end

        # @param position [Position, Array(Integer, Integer)]
        # @return [Integer]
        def describe(position)
          position = PositionNormalizer.normalize(position)
          position.line
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not treat a parameter reassignment inside a block as guaranteed to have run' do
      checker = type_checker(%(
        class Position
          # @return [Integer]
          def line
            1
          end
        end

        module PositionNormalizer
          # @param position [Position, Array(Integer, Integer)]
          # @return [Position]
          def self.normalize(position)
            Position.new
          end
        end

        # @param position [Position, Array(Integer, Integer)]
        # @return [Integer]
        def describe(position)
          [1].each { position = PositionNormalizer.normalize(position) }
          position.line
        end
      ))
      expect(checker.problems.map(&:message)).to eq([
                                                      '#describe return type could not be inferred',
                                                      'Unresolved call to line on Position, Array(Integer, Integer)'
                                                    ])
    end

    it 'still treats a conditional reassignment as guaranteed to have run for a use site inside the same branch' do
      checker = type_checker(%(
        # @param str [String]
        # @param num [Integer]
        # @param flag [Boolean]
        # @return [void]
        def conditional_reassign(str, num, flag)
          local = num
          if flag
            local = str
            local.upcase
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows a variable assigned in the if condition' do
      checker = type_checker(%(
        # @param name [String]
        # @return [Integer]
        def limit_of(name)
          if (md = name.match(/\\[(.*)\\]/))
            md[1].to_i
          else
            0
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows a variable assigned in the right side of an && condition' do
      checker = type_checker(%(
        # @param name [String, nil]
        # @return [Integer]
        def limit_of(name)
          if !name.nil? && (md = name.match(/\\[(.*)\\]/))
            md[1].to_i
          else
            0
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not narrow a variable assigned in the left side of an || condition' do
      checker = type_checker(%(
        # @param name [String]
        # @param fallback [Boolean]
        # @return [Integer]
        def limit_of(name, fallback)
          if (md = name.match(/\\[(.*)\\]/)) || fallback
            md[1].to_i
          else
            0
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to []'])
    end

    it 'treats a variable assigned in the if condition as falsy in the else clause' do
      checker = type_checker(%(
        # @param name [String]
        # @return [Integer]
        def limit_of(name)
          if (md = name.match(/\\[(.*)\\]/))
            0
          else
            md[1].to_i
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to [] on nil, Boolean'])
    end

    it 'uses a branch-local reassignment at a use site later in the same branch' do
      checker = type_checker(%(
        # @param items [Array<String>, nil]
        # @return [void]
        def clean(items)
          if items.nil?
            items = fetch_items
            items.reject! { |i| i.empty? }
          end
        end

        # @return [Array<String>]
        def fetch_items; ['x']; end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not use a reassignment made in a nested branch that may not run' do
      checker = type_checker(%(
        # @param items [Array<String>, nil]
        # @param flag [Boolean]
        # @return [void]
        def clean(items, flag)
          if items.nil?
            if flag
              items = fetch_items
            end
            items.reject! { |i| i.empty? }
          end
        end

        # @return [Array<String>]
        def fetch_items; ['x']; end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to reject! on nil'])
    end

    it 'does not use a branch-local reassignment at a use site before it' do
      checker = type_checker(%(
        # @param items [Array<String>, nil]
        # @return [void]
        def clean(items)
          if items.nil?
            items.reject! { |i| i.empty? }
            items = fetch_items
          end
        end

        # @return [Array<String>]
        def fetch_items; ['x']; end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to reject! on nil'])
    end

    it 'applies a modifier-if guard after the variable was reassigned' do
      checker = type_checker(%(
        # @param name [String]
        # @return [Integer, nil]
        def find(name)
          got = lookup(name)
          return got.length if got

          got = lookup(name)
          got.length if got
        end

        # @param name [String]
        # @return [String, nil]
        def lookup(name); name; end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'applies a modifier-if guard after a reassignment whose block shadows the name' do
      checker = type_checker(%(
        # @param name [String]
        # @return [Integer, nil]
        def find(name)
          got = candidates.find { |got| got == name }
          return got.length if got

          got = candidates.find { |got| got != name }
          got.length if got
        end

        # @return [Array<String>]
        def candidates; []; end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'keeps a guard fact in force until the variable is reassigned' do
      checker = type_checker(%(
        # @param name [String]
        # @return [Integer, nil]
        def find(name)
          got = lookup(name)
          return got.length if got

          got.length
        end

        # @param name [String]
        # @return [String, nil]
        def lookup(name); name; end
      ))
      expect(checker.problems.map(&:message))
        .to eq(['Unresolved call to length on nil, Boolean'])
    end

    it 'does not apply a guard fact past a reassignment that only runs in a branch' do
      checker = type_checker(%(
        # @param name [String]
        # @param flag [Boolean]
        # @return [Integer, nil]
        def find(name, flag)
          got = lookup(name)
          return got.length if got

          if flag
            got = lookup(name)
          end
          got.length
        end

        # @param name [String]
        # @return [String, nil]
        def lookup(name); name; end
      ))
      expect(checker.problems.map(&:message))
        .to eq(['Unresolved call to length on nil, Boolean'])
    end

    it 'narrows a nil-guarded default after the modifier if' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @return [void]
        def guarded_default(tasks)
          tasks = ['a'] if tasks.nil?
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows a nil-guarded default after a non-modifier if' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @return [void]
        def guarded_default(tasks)
          if tasks.nil?
            tasks = ['a']
          end
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows a guarded default assigned in an unless modifier' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @return [void]
        def guarded_default(tasks)
          tasks = ['a'] unless tasks
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows a guarded default assigned in an else clause' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @return [void]
        def guarded_default(tasks)
          if !tasks.nil?
            puts 'have tasks'
          else
            tasks = ['a']
          end
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'narrows only the reassigned variable when an or-condition guards it' do
      checker = type_checker(%(
        # @param xs [Array<String>, nil]
        # @param ys [Array<String>, nil]
        # @return [void]
        def or_guard(xs, ys)
          xs = ['a'] if xs.nil? || ys.nil?
          xs.each { |t| puts t }
          ys.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to each on Array<String>, nil'])
    end

    it 'keeps nil in the type when the guard tests something other than the variable' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @param flag [Boolean]
        # @return [void]
        def unrelated_guard(tasks, flag)
          tasks = ['a'] if flag
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to each on Array<String>, nil'])
    end

    it 'keeps nil in the type when the nil guard does not reassign the variable' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @return [void]
        def no_reassignment(tasks)
          puts 'hi' if tasks.nil?
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to each on Array<String>, nil'])
    end

    it 'keeps nil in the type when the guarded assignment is itself conditional' do
      checker = type_checker(%(
        # @param tasks [Array<String>, nil]
        # @param flag [Boolean]
        # @return [void]
        def nested_conditional_assign(tasks, flag)
          if tasks.nil?
            tasks = ['a'] if flag
          end
          tasks.each { |t| puts t }
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to each on Array<String>, nil'])
    end

    it 'does not let a loop-body reassignment override a reference textually before it' do
      checker = type_checker(%(
        # @param str [String]
        # @param num [Integer]
        # @param flag [Boolean]
        # @return [void]
        def loop_reassign(str, num, flag)
          local = num
          while flag
            local.abs
            local = str
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'updates a local variable type after reassignment to a different literal type' do
      checker = type_checker(%(
        # @return [void]
        def run
          local = 5
          local = 'hello'
          local.upcase
          nil
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'updates an instance variable type after reassignment in the same method' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def run
            @ivar = 5
            @ivar = 'hello'
            @ivar.upcase
            nil
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'resolves a self-referential reassignment against the pre-assignment type' do
      checker = type_checker(%(
        class Repro
          # @param x [String]
          # @return [Integer]
          def foo(x)
            x = x.length
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'supports !@x.nil && @x.y' do
      checker = type_checker(%(
        class Bar
          # @param foo [String, nil]
          def initialize(foo)
            @foo = foo
          end

          def foo?
            !@foo.nil? && @foo.upcase == 'FOO'
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'infers a Boolean return from !!(x.nil? || x < n) on a nilable param' do
      checker = type_checker(%(
        # @param val [Integer, nil]
        # @return [Boolean]
        def check?(val)
          !!(val.nil? || val < 5)
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
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
