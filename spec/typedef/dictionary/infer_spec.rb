# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  def dictionary_for code, position
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    described_class.at(api_map, 'test.rb', position)
  end

  describe '#infer' do
    it 'infers types' do
      code = %(
        # @return [Array<String>]
        def foo; end

        foo.first
      )

      typeset = dictionary_for(code, [4, 12]).infer
      expect(typeset.to_s).to eq('String | nil')
    end

    it 'infers local variables' do
      code = %(
        x = 0
        x

        y = 'foo'
        z = []
      )

      typeset = dictionary_for(code, [2, 8]).infer
      expect(typeset.to_s).to eq('Integer')
    end

    it 'resolves an RBS self return type to the union member that supplied the method' do
      code = %(
        # @type [String, Symbol]
        name = string_or_symbol
        name.to_sym
      )

      typeset = dictionary_for(code, [3, 13]).infer
      expect(typeset.to_s).to eq('Symbol')
    end

    it 'resolves a shared self-returning method separately for each union member' do
      code = %(
        # @type [String, Symbol]
        name = string_or_symbol
        name.itself
      )

      typeset = dictionary_for(code, [3, 13]).infer
      expect(typeset.to_s).to eq('String | Symbol')
    end

    it 'resolves self in a union return type separately for each union member' do
      code = %(
        class Base
          # @return [String, self]
          def pick; end
        end

        class Alpha < Base; end
        class Beta < Base; end

        # @type [Alpha, Beta]
        thing = alpha_or_beta
        thing.pick
      )

      typeset = dictionary_for(code, [11, 15]).infer
      expect(typeset.to_s).to eq('String | Alpha | Beta')
    end

    it 'resolves a YARD @return [self] to the union member that supplied the method' do
      pending 'WIP'
      code = %(
        class Alpha
          # @return [Symbol]
          def to_thing; end
        end

        class Beta
          # @return [self]
          def to_thing; end
        end

        # @type [Alpha, Beta]
        thing = alpha_or_beta
        thing.to_thing
      )

      typeset = dictionary_for(code, [13, 14]).infer
      expect(typeset.to_s).to eq('Symbol | Beta')
    end

    it 'distributes a YARD self nested in a generic across union members' do
      pending 'WIP'
      code = %(
        class Base
          # @return [Array<self>]
          def many; end
        end

        class Alpha < Base; end
        class Beta < Base; end

        # @type [Alpha, Beta]
        thing = alpha_or_beta
        thing.many
      )

      typeset = dictionary_for(code, [11, 16]).infer
      expect(typeset.to_s).to eq('Array[Alpha], Array[Beta]')
    end

    it 'does not leak one union member into a Class#new call resolved on another' do
      code = %(
        class Beta; end

        # @type [Class<Beta>, Class]
        klass = beta_class_or_generic_class
        klass.new
      )

      typeset = dictionary_for(code, [5, 15]).infer
      # The bare `Class` member cannot know what its #new constructs, and Beta must not leak in from the other.
      expect(typeset.to_s).to eq('undefined')
    end

    it 'resolves Class#new the same way regardless of union member order' do
      code = %(
        class Beta; end

        # @type [Class, Class<Beta>]
        klass = generic_or_beta_class
        klass.new
      )

      typeset = dictionary_for(code, [5, 14]).infer
      expect(typeset.to_s).to eq('undefined')
    end

    it 'infers from variable assignments with if conditions' do
      code = %(
        x = if foo
          1
        else
          '2'
        end
        x
      )

      typeset = dictionary_for(code, [5, 8]).infer
      expect(typeset.to_s).to eq('Integer | String')
    end

    it 'infers from variable assignments with case conditions' do
      code = %(
        x = case foo
        when bar
          1
        else
          '2'
        end
        x
      )

      typeset = dictionary_for(code, [7, 8]).infer
      expect(typeset.to_s).to eq('Integer | String')
    end

    it 'infers from method definitions' do
      code = %(
        def foo
          case x
          when y
            1
          else
            '2'
          end
        end
      )

      typeset = dictionary_for(code, [1, 8]).infer
      expect(typeset.to_s).to eq('Integer | String')
    end

    it 'infers types from new subclass calls without a subclass initialize method' do
      code = %(
        class Sup
          def initialize; end
          def meth; end
        end
        class Sub < Sup
          def meth; end
        end

        Sub.new
      )

      typeset = dictionary_for(code, [9, 12]).infer
      expect(typeset.to_s).to eq('Sub')
    end

    it 'pulls types from multiple lines of code' do
      code = %(
        123
        'abc'
      )

      typeset = dictionary_for(code, [2, 13]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'uses last line of a begin expression as return type' do
      code = %(
        begin
          123
          'abc'
        end
      )

      typeset = dictionary_for(code, [4, 11]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'infers booleans from or-nodes passed to !' do
      code = %(
        !([].include?('.') || [].include?('#'))
      )

      typeset = dictionary_for(code, [1, 9]).infer
      expect(typeset.to_s).to eq('Boolean')
    end

    it 'infers last type from and-nodes' do
      code = %(
        [] && ''
      )

      typeset = dictionary_for(code, [1, 16]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'infers multiple types from or-nodes' do
      code = %(
        [] || ''
      )

      typeset = dictionary_for(code, [1, 12]).infer
      expect(typeset.to_s).to eq('Array | String')
    end

    it 'infers Procs from block-pass nodes' do
      code = %(
        x = []
        x.map(&:foo)
      )

      typeset = dictionary_for(code, [2, 14]).infer
      expect(typeset.to_s).to eq('Proc')
    end

    it 'infers Boolean from true' do
      code = %(
        @x = true
      )

      typeset = dictionary_for(code, [1, 10]).infer
      expect(typeset.to_s).to eq('Boolean')
    end

    it 'infers self from Array#new' do
      code = %(
        Array.new
      )

      typeset = dictionary_for(code, [1, 14]).infer
      expect(typeset.to_s).to eq('Array')
    end

    it 'infers self from inherited Object#freeze' do
      code = %(
        Array.new.freeze
      )

      typeset = dictionary_for(code, [1, 18]).infer
      expect(typeset.to_s).to eq('Array')
    end

    it 'infers the nearest constants first' do
      code = %(
        module Outer
          class String; end
        end
        module Outer
          module Inner
            def self.outer_string
              String
            end
          end
        end
      )

      typeset = dictionary_for(code, [6, 21]).infer
      expect(typeset.to_s).to eq('Class[Outer::String]')
    end

    it 'infers rooted constants' do
      code = %(
        module Outer
          class String; end
        end
        module Outer
          module Inner
            def self.core_string
              ::String
            end
          end
        end
      )

      typeset = dictionary_for(code, [6, 21]).infer
      expect(typeset.to_s).to eq('Class[String]')
    end

    it 'infers String from interpolated strings' do
      code = %("#{Object}")

      typeset = dictionary_for(code, [0, 0]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'infers Symbol from symbols' do
      code = ':foo'

      typeset = dictionary_for(code, [0, 0]).infer
      expect(typeset.to_s).to eq('Symbol')
    end

    it 'infers Symbol from quoted symbols' do
      code = ':"foo"'

      typeset = dictionary_for(code, [0, 0]).infer
      expect(typeset.to_s).to eq('Symbol')
    end

    it 'infers Symbol from interpolated symbols' do
      code = %(:"#{Object}")

      typeset = dictionary_for(code, [0, 0]).infer
      expect(typeset.to_s).to eq('Symbol')
    end

    it 'infers namespaces from constant aliases' do
      code = %(
        class Foo
          class Bar; end
        end
        Alias = Foo
        Alias::Bar.new
      )

      typeset = dictionary_for(code, [5, 19]).infer
      expect(typeset.to_s).to eq('Foo::Bar')
    end

    it 'infers instance variables from sequential assignments' do
      code = %(
        def foo
          @foo = nil
          @foo = 'foo'
        end
      )

      typeset = dictionary_for(code, [2, 10]).infer
      expect(typeset.to_s).to eq('nil')

      typeset = dictionary_for(code, [3, 10]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'recognizes nil safe navigation without upstream nil' do
      code = %(
        String.new&.strip
      )

      typeset = dictionary_for(code, [1, 20]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'recognizes nil safe navigation with upstream nil' do
      code = %(
        # @return [String, nil]
        def foo; end
        foo&.upcase
      )

      typeset = dictionary_for(code, [2, 13]).infer
      expect(typeset.to_s).to eq('String | nil')
    end

    it 'infers Class<self> from Object#class' do
      code = %(
        String.new.class
      )

      typeset = dictionary_for(code, [1, 19]).infer
      expect(typeset.to_s).to eq('Class[String]')
    end

    it 'resolves variable and method name collisions' do
      code = %(
        class Example
          # @return [String]
          def stringify; end

          class << self
            # @return [Example]
            def obj(foo); end
          end
        end

        obj = Example.obj
        str = obj.stringify
      )

      typeset = dictionary_for(code, [12, 9]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'infers class variables' do
      code = %(
        class Example
          @@foo = 'string'

          def bar
            @@foo
          end
        end
      )

      typeset = dictionary_for(code, [4, 14]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'understands &. in chains' do
      code = %(
        # @param a [String, nil]
        # @return [String, nil]
        def foo a
          b = a&.upcase
          b
        end

        c = foo 123
        c
      )

      typeset = dictionary_for(code, [4, 17]).infer
      expect(typeset.to_s).to eq('String | nil')

      typeset = dictionary_for(code, [5, 10]).infer
      expect(typeset.to_s).to eq('String | nil')

      typeset = dictionary_for(code, [9, 8]).infer
      expect(typeset.to_s).to eq('String | nil')
    end

    it 'detects block parameter return types from @yieldparam tags' do
      code = %(
        # @yieldparam [Array]
        def yielder; end
        yielder do |things|
          things
        end
      )

      typeset = dictionary_for(code, [4, 11]).infer
      expect(typeset.to_s).to eq('Array')
    end

    it 'infers from superclass return tags' do
      code = %(
        class Superclass
          # @return [Integer]
          def example
          end
        end

        class Subclass < Superclass
        end

        Subclass.new.example
      )

      typeset = dictionary_for(code, [10, 21]).infer
      expect(typeset.to_s).to eq('Integer')
    end

    it 'infers from super calls' do
      code = %(
        class Foo
          # @return [Integer]
          def foo
          end
        end

        class Bar < Foo
          def foo
            bar = super
            bar
            [1,2,3].each do |i|
              baz = super
              baz
            end
          end
        end
      )

      typeset = dictionary_for(code, [10, 12]).infer
      expect(typeset.to_s).to eq('Integer')

      typeset = dictionary_for(code, [13, 14]).infer
      expect(typeset.to_s).to eq('Integer')
    end

    it 'handles resolving String#each_line overloads' do
      code = %(
        def foo
          'abcdef'.each_line do |line|
            line
          end
        end
      )

      typeset = dictionary_for(code, [3, 13]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'handles block method yield scenarios' do
      code = %(
        # @yieldreturn [Integer]
        def foo
          bar = yield
          bar
          [1,2,3].each do |i|
            baz = yield
            baz
          end
        end
      )

      typeset = dictionary_for(code, [4, 10]).infer
      expect(typeset.to_s).to eq('Integer')

      typeset = dictionary_for(code, [7, 12]).infer
      expect(typeset.to_s).to eq('Integer')
    end

    it 'expands local variable types with multiple assignment pins' do
      code = %(
        bar = 'a'
        if baz
          bar = :foo
        elsif qux
          bar = 123
        end
        bar
      )

      typeset = dictionary_for(code, [7, 8]).infer
      expect(typeset.to_s).to eq('Integer | Symbol | String')
    end

    it 'infers that type of argument has been overridden' do
      code = %(
        def foo a
          a = 'foo'
          a
        end
      )

      typeset = dictionary_for(code, [3, 10]).infer
      expect(typeset.to_s).to eq('String')
    end

    it 'infers types from named macros' do
      code = %(
        # @!macro firstarg
        #   @return [$1]
        class Foo
          # @macro firstarg
          def bar klass
          end
        end
        Foo.new.bar(String)
      )

      typeset = dictionary_for(code, [8, 16]).infer
      expect(typeset.to_s).to eq('String')
    end
  end
end
