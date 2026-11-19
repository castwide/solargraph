# frozen_string_literal: true

describe Solargraph::Typedef::Filter do
  describe '#typeset' do
    it 'selects the first declared method pin' do
      pins = [
        Solargraph::Pin::Method.new(return_type: Solargraph::ComplexType::UNDEFINED),
        Solargraph::Pin::Method.new(return_type: Solargraph::ComplexType.parse('Integer'))
      ]
      typeset = described_class.new(nil, pins, nil).typeset
      expect(typeset.to_s).to eq('Integer')
    end
  end
end
