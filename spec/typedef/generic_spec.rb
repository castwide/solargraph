# frozen_string_literal: true

describe Solargraph::Typedef::Generic do
  it 'formats properly' do
    generic = described_class.new('T')
    expect(generic.to_s).to eq('generic<T>')
  end
end
