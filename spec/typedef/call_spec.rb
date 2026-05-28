# frozen_string_literal: true

# @todo describe Linker::Call
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
