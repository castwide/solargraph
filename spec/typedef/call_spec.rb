# frozen_string_literal: true

# @todo describe Linker::Call
describe Solargraph::Typedef::Dictionary do
  it 'handles super calls to same method' do
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end

  it 'infers return types based on yield call and @yieldreturn' do
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end

  it 'infers return types based only on yield call and @yieldreturn' do
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end

  it 'adds virtual constructors for <Class>.new calls with conflicting return types' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [String]
        def self.new; end
      end
      Foo.new
    ), 'test.rb')
    api_map.map source

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'infers constant return types via returns, ignoring blocks' do
    source = Solargraph::Source.load_string(%(
      def yielder(&blk)
        "foo"
      end

      yielder do
        123
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [7, 8])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end

  it 'infers types from union type' do
    source = Solargraph::Source.load_string(%(
      # @type [String, Float]
      list = string_or_float
      list.upcase
      list.ceil
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    dictionary = described_class.new(api_map, 'test.rb', [3, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')

    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')

    dictionary = described_class.new(api_map, 'test.rb', [4, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Enumerator[Integer | String]')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('undefined')
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
    typeset = dictionary.infer
    pending 'Hash is inferred as Hash[String | undefined]'
    expect(typeset.to_s).to eq('Array | Hash[String, undefined] | String | Integer | nil')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('undefined')
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
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer | nil')
  end

  it 'does not mis-parse generic methods with type constraints' do
    pending 'WIP'
    source = Solargraph::Source.load_string(%(
      def bl
        out = (Encoding.default_external = 'UTF-8')
        out
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 8])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'handles this weird case' do
    pending 'Generic and signature issues'
    source = Solargraph::Source.load_string(%(
      Encoding.default_external = 'UTF-8'
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new(loose_unions: false).map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 15])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'extracts generic values from parameters' do
    source = Solargraph::Source.load_string(%(
      # @generic T
      # @param klass [Class<generic<T>>]
      # @return [Set<generic<T>>]
      def foo klass; end

      foo(String)
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 6])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Set[String]')
  end
end
