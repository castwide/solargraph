# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  it 'handles super calls to same method' do
    pending 'Returns [Integer, Integer]'
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        def my_method
          123
        end
      end
      class Bar < Foo
        def my_method
          456 + super
        end
      end
      Bar.new.my_method), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [11, 14])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers return types based on yield call and @yieldreturn' do
    pending 'Block suport'
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @yieldreturn [Integer]
        def my_method(&block)
          yield
        end
      end
      Foo.new.my_method), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 14])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers return types based only on yield call and @yieldreturn' do
    pending 'Block support'
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @yieldreturn [Integer]
        def my_method(&block)
          yield
        end
      end
      Foo.new.my_method { "foo" }), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 32])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'adds virtual constructors for <Class>.new calls with conflicting return types' do
    pending "May need to skip probes for expanded types"
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [String]
        def self.new; end
      end
      Foo.new
    ), 'test.rb')
    api_map.map source
    # chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    # expect(type.tag).to eq('String')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
  end

  it 'infers types from macros' do
    pending 'WIP'
    source = Solargraph::Source.load_string(%(
      class Foo
        # @!macro
        #   @return [$1]
        def self.bar; end
      end
      Foo.bar(String)
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 10])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
  end

  it 'infers generic types from Array#reverse' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      list = array_of_strings
      list.reverse
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 11])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array[String]'])
  end

  it 'infers constant return types via returns, ignoring blocks' do
    pending "Block support"
    source = Solargraph::Source.load_string(%(
      def yielder(&blk)
        "foo"
      end

      yielder do
        123
      end
    ), 'test.rb')
    # api_map = Solargraph::ApiMap.new
    # api_map.map source
    # chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 8))
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    # expect(type.simple_tags).to eq('String')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 8])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array[String]'])
  end

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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array[String]'])
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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Hash[String, Baz]'])
  end

  it 'infers method return types' do
    source = Solargraph::Source.load_string(%(
      def bar
        123
      end

      def baz
        bar
      end

      baz
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [9, 9])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers method return types based on method generic' do
    pending('deeper inference support')

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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
  end

  it 'infers method return types with unused blocks' do
    source = Solargraph::Source.load_string(%(
      def bar
        123
      end

      def baz(&block)
        bar
      end

      baz { "foo" }
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [9, 9])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers generic types from @generic tag' do
    pending 'Signature support'
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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array[String]'])

    dictionary = described_class.new(api_map, 'test.rb', [13, 20])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array'])
  end

  it 'infers generic return types from block from yield being a return node' do
    pending('deeper inference support')

    source = Solargraph::Source.load_string(%(
      def yielder(&blk)
        yield
      end

      yielder do
        123
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 9])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers types from union type' do
    source = Solargraph::Source.load_string(%(
      # @type [String, Float]
      list = string_or_float
      list.upcase
      list.ceil
    ), 'test.rb')
    # api_map = Solargraph::ApiMap.new
    # api_map.map source

    # chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    # expect(type.tag).to eq('String')

    # chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    # expect(type.tag).to eq('Integer')

    api_map = Solargraph::ApiMap.new.map(source)

    dictionary = described_class.new(api_map, 'test.rb', [3, 11])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])

    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    types = dictionary.infer
    pending "[Integer, Float, Integer, Numeric]"
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'infers generic types from union type' do
    source = Solargraph::Source.load_string(%(
      # @type [String, Array<Integer>]
      list = string_or_integer
      list.upcase
      list.each
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    api_map = Solargraph::ApiMap.new.map(source)

    dictionary = described_class.new(api_map, 'test.rb', [3, 11])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])

    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    types = dictionary.infer
    pending 'Missing generic expansion'
    expect(types.map(&:to_s)).to eq(['Integer'])
  end

  it 'allows calls off of nilable objects by default' do
    source = Solargraph::Source.load_string(%(
      # @type [String, nil]
      f = foo
      a = f.upcase
      a
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 6])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
  end

  it 'denies calls off of nilable objects when loose union mode is off' do
    pending 'WIP'
    source = Solargraph::Source.load_string(%(
      # @type [String, nil]
      f = foo
      a = f.upcase
      a
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 6])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['undefined'])
  end

  it 'preserves unions in value position in Hash' do
    source = Solargraph::Source.load_string(%(
      # @param params [Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}]
      def foo(params)
        position = params['position']
        position
        col = position['character']
        col
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 8])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Array', 'Hash[String, undefined]', 'String', 'Integer', 'nil'])
  end

  it 'preserves undefined and underdefined types in resolution' do
    source = Solargraph::Source.load_string(%(
      # @param params [Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}]
      def foo(params)
        position = params['position']
        position
        col = position['character']
        col
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 8])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['undefined'])
  end

  it 'correctly looks up civars' do
    source = Solargraph::Source.load_string(%(
      class Foo
        BAZ = /aaa/

        # @param comment [String]
        def bar(comment)
          b = ("foo" =~ BAZ)
          b
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 10])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Integer', 'nil'])
  end

  it 'does not mis-parse generic methods with type constraints' do
    source = Solargraph::Source.load_string(%(
      def bl
        out = (Encoding.default_external = 'UTF-8')
        out
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 8])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
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
            # @return [void]
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
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['Set[Foo::Bar::Symbol]'])
  end

  it 'handles this weird case' do
    pending 'Generic and signature issues'
    source = Solargraph::Source.load_string(%(
      Encoding.default_external = 'UTF-8'
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 15])
    types = dictionary.infer
    expect(types.map(&:to_s)).to eq(['String'])
  end
end
