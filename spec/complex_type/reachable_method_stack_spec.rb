# frozen_string_literal: true

# #reachable_method_stack answers with every pin implementing a method,
# highest precedence first, or none when a named type does not provide it.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }

  describe 'UniqueType#reachable_method_stack' do
    it 'answers with the method stack' do
      type = described_class.parse('::String').items.first
      expect(type.reachable_method_stack(api_map, 'upcase').map(&:path)).to eq(['String#upcase'])
    end

    it 'answers with every definition, highest precedence first' do
      api_map.map Solargraph::Source.load_string(%(
        class Sup
          def foo; end
        end
        class Sub < Sup
          def foo; end
        end
      ), 'test.rb')
      type = described_class.parse('::Sub').items.first
      expect(type.reachable_method_stack(api_map, 'foo').map(&:path)).to eq(['Sub#foo', 'Sup#foo'])
    end

    it 'answers empty when the type does not define the method' do
      type = described_class.parse('::String').items.first
      expect(type.reachable_method_stack(api_map, 'frobnicate')).to eq([])
    end

    it 'answers with a duck method for the method a duck type names' do
      type = described_class.parse('#frobnicate').items.first
      expect(type.reachable_method_stack(api_map, 'frobnicate').map(&:name)).to eq(['frobnicate'])
    end
  end

  describe '#reachable_method_stack' do
    it 'gathers the pins of every member of a union' do
      type = described_class.parse('::String', '::Symbol')
      expect(type.reachable_method_stack(api_map, 'upcase').map(&:path)).to eq(['String#upcase', 'Symbol#upcase'])
    end

    it 'keeps the pins of the members that resolve under loose unions' do
      type = described_class.parse('::String', '::Integer')
      expect(type.reachable_method_stack(api_map, 'upcase').map(&:path)).to eq(['String#upcase'])
    end

    it 'answers empty when a member does not resolve and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      type = described_class.parse('::String', '::Integer')
      expect(type.reachable_method_stack(strict_map, 'upcase')).to eq([])
    end

    it 'answers empty when no member resolves' do
      type = described_class.parse('::String', '::Integer')
      expect(type.reachable_method_stack(api_map, 'frobnicate')).to eq([])
    end
  end
end
