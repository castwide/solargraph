# frozen_string_literal: true

# #method_stack_pins answers with the pins implementing a method, or nil
# when a named type does not provide it.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }

  describe 'UniqueType#method_stack_pins' do
    it 'answers with the first pin of the method stack' do
      type = described_class.parse('::String').items.first
      expect(type.method_stack_pins('upcase', api_map).map(&:path)).to eq(['String#upcase'])
    end

    it 'answers nil when the type does not define the method' do
      type = described_class.parse('::String').items.first
      expect(type.method_stack_pins('frobnicate', api_map)).to be_nil
    end

    it 'answers with a duck method for the method a duck type names' do
      type = described_class.parse('#frobnicate').items.first
      expect(type.method_stack_pins('frobnicate', api_map).map(&:name)).to eq(['frobnicate'])
    end
  end

  describe '#method_stack_pins' do
    it 'gathers the pins of every member of a union' do
      type = described_class.parse('::String', '::Symbol')
      expect(type.method_stack_pins('upcase', api_map).map(&:path)).to eq(['String#upcase', 'Symbol#upcase'])
    end

    it 'keeps the pins of the members that resolve under loose unions' do
      type = described_class.parse('::String', '::Integer')
      expect(type.method_stack_pins('upcase', api_map).map(&:path)).to eq(['String#upcase'])
    end

    it 'answers nothing when a member does not resolve and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      type = described_class.parse('::String', '::Integer')
      expect(type.method_stack_pins('upcase', strict_map)).to eq([])
    end
  end
end
