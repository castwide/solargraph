# frozen_string_literal: true

describe Solargraph::Pin::MethodAlias do
  describe '#to_rbs' do
    it 'generates RBS from simple alias' do
      method_alias = described_class.new(name: 'name', original: 'original_name')

      expect(method_alias.to_rbs).to eq('alias name original_name')
    end

    it 'generates RBS from static alias' do
      method_alias = described_class.new(name: 'name', original: 'original_name', scope: :class)

      expect(method_alias.to_rbs).to eq('alias self.name self.original_name')
    end
  end
end
