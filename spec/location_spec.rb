# frozen_string_literal: true

describe Solargraph::Location do
  it 'is not RBS when it has no filename' do
    location = described_class.new(nil, Solargraph::Range.from_to(0, 0, 0, 0))
    expect(location.rbs?).to be(false)
  end
end
