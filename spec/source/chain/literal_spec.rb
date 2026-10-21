# frozen_string_literal: true

describe Solargraph::Source::Chain::Literal do
  it 'resolves an instance of a literal' do
    literal = described_class.new('String', nil)
    api_map = Solargraph::ApiMap.new
    pin = literal.resolve(api_map, nil, nil).first
    expect(pin.return_type.tag).to eq('String')
  end

  it 'does not corrupt a string literal containing a comma, once literal typing is restored' do
    pending 'https://github.com/castwide/solargraph/pull/1223'
    node = Solargraph::Parser.parse("'a, b'", 'test.rb', 0)
    literal = described_class.new('String', node)
    api_map = Solargraph::ApiMap.new
    pin = literal.resolve(api_map, nil, nil).first
    expect(pin.return_type.tag).to eq('"a, b"')
  end
end
