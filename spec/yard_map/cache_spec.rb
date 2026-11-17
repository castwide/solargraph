# frozen_string_literal: true

describe Solargraph::YardMap::Cache do
  let(:cache) { described_class.new }
  let(:pins) { [Solargraph::Pin::Namespace.new(name: 'Foo')] }

  it 'returns the pins previously set for a path' do
    cache.set_path_pins('foo.rb', pins)
    expect(cache.get_path_pins('foo.rb')).to eq(pins)
  end

  it 'returns nil for a path that was never set' do
    expect(cache.get_path_pins('missing.rb')).to be_nil
  end
end
