# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  it 'handles simple nil-removal' do
    source = Solargraph::Source.load_string(%(
      # @param a [Integer, nil]
      def foo a
        b = a || 10
        b
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 8])
    # @todo Unnecessary conversion
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Integer')
  end

  it 'removes nil from more complex cases' do
    source = Solargraph::Source.load_string(%(
      def foo
        out = ENV['BAR'] ||
          File.join(Dir.home, '.config', 'solargraph', 'config.yml')
        out
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 8])
    # @todo Unnecessary conversion
    types = dictionary.infer.types
    expect(types.map(&:to_s)).to eq(['String'])
  end
end
