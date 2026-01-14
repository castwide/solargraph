# frozen_string_literal: true

describe Solargraph::Source::Chain::ZSuper do
  it 'resolves super' do
    head = described_class.new('super')
    npin = Solargraph::Pin::Namespace.new(name: 'Substring')
    scpin = Solargraph::Pin::Reference::Superclass.new(closure: npin, name: 'String')
    mpin = Solargraph::Pin::Method.new(closure: npin, name: 'upcase', scope: :instance, visibility: :public)
    api_map = Solargraph::ApiMap.new(pins: [npin, scpin, mpin])
    spin = head.resolve(api_map, mpin, []).first
    expect(spin.path).to eq('String#upcase')
  end
end
