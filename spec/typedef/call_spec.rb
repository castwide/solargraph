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
end
