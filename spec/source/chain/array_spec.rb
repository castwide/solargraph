# frozen_string_literal: true

describe Solargraph::Source::Chain::Array do
  it 'resolves an instance of an array' do
    literal = described_class.new([], nil)
    pin = literal.resolve(nil, nil, nil).first
    expect(pin.return_type.tag).to eq('Array')
  end

  it 'resolves a homogeneous array literal to a parameterized Array' do
    source = Solargraph::Source.load_string(%(
      a = [1, 2, 3]
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 6])
    type = clip.infer
    expect(type.to_s).to eq('Array<Integer>')
  end

  it 'resolves a heterogeneous array literal to a fixed tuple Array' do
    source = Solargraph::Source.load_string(%(
      a = [1, 'a']
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 6])
    type = clip.infer
    expect(type.to_s).to eq('Array(Integer, String)')
  end
end
