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

    it 'does not leak nil from an earlier &. into an unrelated later call in the same chain' do
      checker = type_checker(%(
        class Repro
          # @param x [String, nil]
          # @return [Boolean]
          def process(x)
            x&.to_s == '1'
          end
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'still flags a chain ending in a safe navigation call as nullable' do
      checker = type_checker(%(
        class Repro
          # @param x [String, nil]
          # @return [String]
          def process(x)
            x&.to_s
          end
        end
      ))
      expect(checker.problems.map(&:message)).not_to be_empty
    end

    it 'still flags nil leaking through a self-returning call after an earlier &.' do
      checker = type_checker(%(
        class Repro
          # @param x [String, nil]
          # @return [String]
          def process(x)
            x&.to_s.itself
          end
        end
      ))
      expect(checker.problems.map(&:message)).not_to be_empty
    end

    it 'does not flag a call after &. whose result on NilClass is a fixed non-nil type' do
      checker = type_checker(%(
        class Repro
          # @param x [String, nil]
          # @return [Integer]
          def process(x)
            x&.to_s.to_i
          end
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

    it 'applies a yieldparam type declared on a block-form @overload' do
      checker = type_checker(%(
        # @overload build
        #   @return [String]
        # @overload build
        #   @yieldparam widget [String]
        #   @return [void]
        def build
          return 'hi' unless block_given?

          yield 'hi'
        end

        build do |w|
          w.upcase
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
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

    it 'resolves Hash#fetch on a literal-keyed Hash with no intersection involved' do
      checker = type_checker(%(
        class Repro
          # @param period [Hash{"Index" => Float}]
          # @return [void]
          def process(period)
            # @type [Float]
            index = period.fetch("Index")
          end
        end
    ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'always dispatches a same-class generic method through the first union member' do
      pending 'Call#inferred_pins binds a generic against the first union/intersection member only'
      checker = type_checker(%(
        class Repro
          # @param period [Hash{"Index" => Float}, Hash{"Triggers" => Array<Hash{"Name" => String}>}]
          # @return [void]
          def process(period)
            # @type [Float]
            index = period.fetch("Index")
          end
        end
    ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    context 'with intersection types' do
      it 'accepts an intersection-typed argument where any one conjunct is expected' do
        checker = type_checker(%(
          class Asana; class Resources; class Project; end; end; end
          class Mocha; class Mock; end; end

          class Consumer
            # @param project_obj [Asana::Resources::Project]
            # @return [void]
            def project_to_h(project_obj); end
          end

          class MockFactory
            # @sg-ignore Mocha::Mock configured with responds_like_instance_of
            #   duck-types as Asana::Resources::Project at every call site.
            # @return [Mocha::Mock & Asana::Resources::Project]
            def make_mock
              Mocha::Mock.new
            end
          end

          Consumer.new.project_to_h(MockFactory.new.make_mock)
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'still rejects a plain conjunct type that does not satisfy the expected type' do
        checker = type_checker(%(
          class Asana; class Resources; class Project; end; end; end
          class Mocha; class Mock; end; end

          class Consumer
            # @param project_obj [Asana::Resources::Project]
            # @return [void]
            def project_to_h(project_obj); end
          end

          Consumer.new.project_to_h(Mocha::Mock.new)
      ))
        expect(checker.problems.map(&:message))
          .to include('Wrong argument type for Consumer#project_to_h: project_obj expected Asana::Resources::Project, received Mocha::Mock')
      end

      it 'accepts an intersection-typed argument where the duck-typed conjunct is expected' do
        # Duck-typed subtyping needs *some* conjunct to satisfy it, not
        # specifically the first one that Intersection#namespace/#scope
        # delegate to.
        checker = type_checker(%(
          # @param callback [#quack]
          # @return [void]
          def notify(callback); end

          # @param x [String & #quack]
          # @return [void]
          def relay(x)
            notify(x)
          end
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'still rejects an intersection-typed argument when no conjunct satisfies the duck-typed expectation' do
        checker = type_checker(%(
          # @param callback [#quack]
          # @return [void]
          def notify(callback); end

          # @param x [String & Integer]
          # @return [void]
          def relay(x)
            notify(x)
          end
      ))
        expect(checker.problems.map(&:message))
          .to include('Wrong argument type for #notify: callback expected #quack, received String & Integer')
      end

      it 'dispatches generic methods per-conjunct when intersecting two instantiations of the same generic class' do
        # Both conjuncts resolve to a pin with the same path (Hash#fetch)
        # but different, already-resolved return types, so dispatch keys on
        # path *and* return type, then narrows to the conjunct whose key
        # matches the call's literal argument. Overload resolution can't
        # do that on its own, since it runs per conjunct and both
        # conjuncts yield a pin with the same path.
        pending 'https://github.com/castwide/solargraph/pull/1223'
        checker = type_checker(%(
          class Repro
            # @param period [Hash{"Index" => Float} & Hash{"Triggers" => Array<Hash{"Name" => String}>}]
            # @return [void]
            def process(period)
              # @type [Float]
              index = period.fetch("Index")

              # @type [Array<Hash{"Name" => String}>]
              triggers = period.fetch("Triggers")
            end
          end
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'dispatches generic methods per-conjunct regardless of conjunct order' do
        pending 'https://github.com/castwide/solargraph/pull/1223'
        checker = type_checker(%(
          class Repro
            # @param period [Hash{"Triggers" => Array<Hash{"Name" => String}>} & Hash{"Index" => Float}]
            # @return [void]
            def process(period)
              # @type [Array<Hash{"Name" => String}>]
              triggers = period.fetch("Triggers")

              # @type [Float]
              index = period.fetch("Index")
            end
          end
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'dispatches generic methods per-conjunct for symbol keys' do
        # Symbols already infer as literal types, so per-overload matching
        # rejects the non-matching conjunct on its own here - a pin whose
        # overloads all fail falls through to its declared return type
        # rather than being dropped, so only Call#argument_verified_conjuncts
        # actually removes it.
        pending 'https://github.com/castwide/solargraph/pull/1223'
        checker = type_checker(%(
          class Repro
            # @param period [Hash{:Index => Float} & Hash{:Triggers => Array<Hash{:Name => String}>}]
            # @return [void]
            def process(period)
              # @type [Float]
              index = period.fetch(:Index)

              # @type [Array<Hash{:Name => String}>]
              triggers = period.fetch(:Triggers)
            end
          end
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'resolves a non-generic method shared by both conjuncts of a same-class intersection' do
        checker = type_checker(%(
          class Repro
            # @param period [Hash{"Index" => Float} & Hash{"Triggers" => Array<Hash{"Name" => String}>}]
            # @return [void]
            def process(period)
              # @type [Integer]
              n = period.size
            end
          end
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'resolves a call to a method defined on just one conjunct of an intersection-typed receiver' do
        # Method lookup gives an intersection's conjuncts "any one is
        # enough" semantics (A & B <: A, A & B <: B), unlike a union, where
        # every alternative has to define the method.
        checker = type_checker(%(
          class A
            # @return [void]
            def foo; end
          end

          class B
            # @return [void]
            def bar; end
          end

          class Factory
            # @sg-ignore A.new duck-types as A & B for this repro
            # @return [A & B]
            def make
              A.new
            end
          end

          Factory.new.make.foo
          Factory.new.make.bar
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'dispatches to the conjunct whose parameter type actually accepts the argument' do
        # Same problem as the Hash-record specs above, generalized:
        # narrowing an intersection's conjuncts by argument fit isn't
        # Hash-key-specific, it's ordinary overload matching applied
        # per conjunct instead of per signature.
        checker = type_checker(%(
          class A
            # @param x [String]
            # @return [Integer]
            def pick(x)
              1
            end
          end

          class B
            # @param x [Symbol]
            # @return [Float]
            def pick(x)
              1.0
            end
          end

          class Factory
            # @sg-ignore A.new duck-types as A & B for this repro
            # @return [A & B]
            def make
              A.new
            end
          end

          # @type [Integer]
          from_a = Factory.new.make.pick("hello")

          # @type [Float]
          from_b = Factory.new.make.pick(:hello)
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'resolves a call to a method inherited from a common ancestor of both conjuncts' do
        checker = type_checker(%(
          class A
            # @return [void]
            def foo; end
          end

          class B
            # @return [void]
            def bar; end
          end

          class Factory
            # @sg-ignore A.new duck-types as A & B for this repro
            # @return [A & B]
            def make
              A.new
            end
          end

          # @type [String]
          s = Factory.new.make.to_s
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'resolves a conjunct method on an intersection-typed local variable, not just a call chain' do
        checker = type_checker(%(
          class A
            # @return [void]
            def foo; end
          end

          class B
            # @return [void]
            def bar; end
          end

          # @sg-ignore A.new duck-types as A & B for this repro
          # @type [A & B]
          value = A.new

          value.foo
          value.bar
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'resolves conjunct methods on a three-way intersection' do
        checker = type_checker(%(
          class A
            # @return [void]
            def foo; end
          end

          class B
            # @return [void]
            def bar; end
          end

          class C
            # @return [void]
            def baz; end
          end

          class Factory
            # @sg-ignore A.new duck-types as A & B & C for this repro
            # @return [A & B & C]
            def make
              A.new
            end
          end

          Factory.new.make.foo
          Factory.new.make.bar
          Factory.new.make.baz
      ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      # Passes with and without the conjunct resolution: an unbound
      # generic return is accepted leniently, so this is a
      # no-regression check. The mismatch spec below is the
      # discriminating one.
      it 'binds a generic declared only inside an intersection @param' do
        checker = type_checker(%(
          class Factory
            # @generic T
            # @param clazz [Class<generic<T>> & #new]
            # @return [Class<generic<T>>]
            def echo(clazz)
              clazz
            end

            # @return [Class<String>]
            def use
              echo(String)
            end
          end
        ))
        expect(checker.problems.map(&:message)).to be_empty
      end

      it 'reports a mismatch against the generic bound through the intersection' do
        checker = type_checker(%(
          class Factory
            # @generic T
            # @param clazz [Class<generic<T>> & #new]
            # @return [Class<generic<T>>]
            def echo(clazz)
              clazz
            end

            # @return [Class<Integer>]
            def use
              echo(String)
            end
          end
        ))
        expect(checker.problems.map(&:message))
          .to eq(['Declared return type ::Class<::Integer> does not match inferred type ::Class<::String> ' \
                  'for Factory#use'])
      end
    end
  end
end
