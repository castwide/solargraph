# frozen_string_literal: true

describe Solargraph::Pin::Signature do
  it 'defaults return_type to undefined when none is given' do
    method = Solargraph::Pin::Method.new(name: 'foo', closure: Solargraph::Pin::ROOT_PIN)
    pin = described_class.new(closure: method)
    expect(pin.return_type).to be_undefined
  end
end
