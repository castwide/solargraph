# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  describe '#define' do
    it 'resolves methods with parameters' do
      source = Solargraph::Source.load_string(%(
        # @return [Array<String>]
        def foo; end

        foo.first
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [4, 12])
      pins = dictionary.define
      expect(pins.map(&:path)).to eq(['Array#first', 'Enumerable#first'])
    end

    it 'resolves self' do
      source = Solargraph::Source.load_string(%(
        class Foo
          def bar; end

          def baz
            self.bar
          end
        end
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [5, 19])
      pins = dictionary.define
      expect(pins.map(&:path)).to eq(['Foo#bar'])
    end

    it 'expands named macros' do
      source = Solargraph::Source.load_string(%(
        # @!macro [new] klassify
        #   @return [Array<$1>]
        class Example
          # @macro klassify
          def foo(klass)
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new.map(source)
      api_map.get_path_pins('Example#foo').first
      dictionary = described_class.new(api_map, 'test.rb', [5, 14])
      defined = dictionary.define.first
      expect(defined.typedef_typeset.to_s).to eq('Array[klass]')
    end
  end

  describe '#infer' do
    it 'infers types' do
      source = Solargraph::Source.load_string(%(
        # @return [Array<String>]
        def foo; end

        foo.first
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [4, 12])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('String | nil')
    end

    it 'infers local variables' do
      source = Solargraph::Source.load_string(%(
        x = 0
        x

        y = 'foo'
        z = []
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [2, 8])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('Integer')
    end

    it 'resolves an RBS self return type to the union member that supplied the method' do
      source = Solargraph::Source.load_string(%(
        # @type [String, Symbol]
        name = string_or_symbol
        name.to_sym
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [3, 13])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('Symbol')
    end

    it 'resolves a shared self-returning method separately for each union member' do
      source = Solargraph::Source.load_string(%(
        # @type [String, Symbol]
        name = string_or_symbol
        name.itself
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [3, 13])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('String | Symbol')
    end

    it 'resolves self in a union return type separately for each union member' do
      source = Solargraph::Source.load_string(%(
        class Base
          # @return [String, self]
          def pick; end
        end

        class Alpha < Base; end
        class Beta < Base; end

        # @type [Alpha, Beta]
        thing = alpha_or_beta
        thing.pick
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [11, 15])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('String | Alpha | Beta')
    end

    it 'resolves a YARD @return [self] to the union member that supplied the method' do
      pending 'WIP'
      source = Solargraph::Source.load_string(%(
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
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [13, 14])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('Symbol | Beta')
    end

    it 'distributes a YARD self nested in a generic across union members' do
      pending 'WIP'
      source = Solargraph::Source.load_string(%(
        class Base
          # @return [Array<self>]
          def many; end
        end

        class Alpha < Base; end
        class Beta < Base; end

        # @type [Alpha, Beta]
        thing = alpha_or_beta
        thing.many
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [11, 16])
      # Base#many is one shared pin, so the nested `self` resolves per member, not to Array<Alpha, Beta>.
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('Array[Alpha], Array[Beta]')
    end

    it 'does not leak one union member into a Class#new call resolved on another' do
      source = Solargraph::Source.load_string(%(
        class Beta; end

        # @type [Class<Beta>, Class]
        klass = beta_class_or_generic_class
        klass.new
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [5, 15])
      typeset = dictionary.infer
      # The bare `Class` member cannot know what its #new constructs, and Beta must not leak in from the other.
      expect(typeset.to_s).to eq('undefined')
    end

    it 'resolves Class#new the same way regardless of union member order' do
      source = Solargraph::Source.load_string(%(
        class Beta; end

        # @type [Class, Class<Beta>]
        klass = generic_or_beta_class
        klass.new
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [5, 14])
      typeset = dictionary.infer
      expect(typeset.to_s).to eq('undefined')
    end
  end
end
