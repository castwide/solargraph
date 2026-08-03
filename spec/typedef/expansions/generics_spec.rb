# frozen_string_literal: true

# @todo describe Generics
describe Solargraph::Typedef::Dictionary do
  it 'infers generic parameterized types through module inclusion' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      module Foo
        # @return [Array<generic<GenericTypeParam>>]
        def baz
        end
      end

      class Baz
        # @return [Baz<String>]
        def self.bar
        end

        include Foo
      end

      Baz.bar.baz
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [16, 15])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array[String]')
  end

  it 'infers generic-class method return values with self reference' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      module Foo
        # @return [Hash<generic<GenericTypeParam>, self>]
        def baz
        end
      end

      class Baz
        # @return [Baz<String>]
        def self.bar
        end

        include Foo
      end

      Baz.bar.baz
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [16, 15])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Hash[String, Baz]')
  end

  it 'infers method return types based on method generic' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @Generic A
        # @param x [generic<A>]
        # @return [generic<A>]
        def bar(x); end
      end

      foo = Foo.new
      a = foo.bar("baz")
      a
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [10, 6])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'infers generic types from @generic tag' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      class Foo
        # @return [Foo<String>]
        def self.bar
        end

        # @return [Array<generic<GenericTypeParam>>]
        def baz
        end
      end

      Foo.bar.baz
      Foo.bar.baz.first
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    dictionary = described_class.new(api_map, 'test.rb', [12, 15])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array[String]')

    dictionary = described_class.new(api_map, 'test.rb', [13, 20])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String | nil')
  end

  it 'calculates class return type based on class generic' do
    source = Solargraph::Source.load_string(%(
      # @generic A
      class Foo
        # @return [generic<A>]
        def bar; end
      end

      # @type [Foo<String>]
      f = Foo.new
      a = f.bar
      a
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [10, 7])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'sends proper gates in ProxyType' do
    source = Solargraph::Source.load_string(%(
      module Foo
        module Bar
          class Symbol
          end
        end
      end

      module Foo
        module Baz
          class Quux
            # @return [void] @todo This return tag blocks inference
            def foo
              s = objects_by_class(Bar::Symbol)
              s
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
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [14, 14])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Set[Foo::Bar::Symbol]')
  end

  it 'gracefully handles requests for type of generic method in chain' do
    source = Solargraph::Source.load_string(%(
      # @generic T
      # @param x [generic<T>]
      # @return [generic<T>]}
      def foo(x); x; end
      foo('string')
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [5, 7])
    expect { dictionary.infer }.not_to raise_error

    # @todo The original test suggested that the method call should be inferred
    #   as [String]. That functionality is currently possible with macros. I'm
    #   not sure that generics are a good fit here.
  end

  describe '#names' do
    let(:pin) { double(Solargraph::Pin::Base, typedef_generics: [], closure: nil) }
    let(:receiver) { double(Solargraph::Pin::Base, typedef_generics: [], closure: nil) }

    it 'finds generic names from source pins' do
      source = Solargraph::Source.load_string(%(
        # @generic T
        class Example
          def foo; end
        end
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      pin = api_map.get_path_pins('Example#foo').first
      generics = Solargraph::Typedef::Expansions::Generics.new(api_map, pin, receiver)
      expect(generics.names).to eq(['T'])
    end

    it 'finds generic names from receiver pins' do
      source = Solargraph::Source.load_string(%(
        class Example
          # @return [Array]
          def foo; end
        end
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      # Simulating the receiver
      receiver = api_map.get_path_pins('Array').first
      generics = Solargraph::Typedef::Expansions::Generics.new(api_map, pin, receiver)
      expect(generics.names).to eq(['Elem'])
    end
  end

  it 'infers generic types from Array#reverse' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      list = array_of_strings
      list.reverse
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array[String]')
  end
end
