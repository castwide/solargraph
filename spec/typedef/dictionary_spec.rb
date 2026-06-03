# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  it 'resolves methods with parameters' do
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def foo; end

      foo.first
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 10])
    pins = dictionary.define
    expect(pins.map(&:path)).to eq(['Array#first', 'Enumerable#first'])
  end

  it 'infers types' do
    pending 'Overload/signature issue'
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def foo; end

      foo.first
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 10])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String | nil')
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
    dictionary = described_class.new(api_map, 'test.rb', [5, 17])
    pins = dictionary.define
    expect(pins.map(&:path)).to eq(['Foo#bar'])
  end

  it 'infers local variables' do
    source = Solargraph::Source.load_string(%(
      x = 0
      x

      y = 'foo'
      z = []
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [2, 6])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end
end
