# frozen_string_literal: true

describe Solargraph::Pin::Signature do
  it 'defaults return_type to undefined when none is given' do
    pin = described_class.new
    expect(pin.return_type).to be_undefined
  end
end
