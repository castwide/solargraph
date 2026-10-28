# frozen_string_literal: true

# #qualify_parts hands each named part of a type to the block and
# rebuilds the type from the answers; ApiMap::Constants#qualify_type
# uses it to resolve every member of a union, not only the first.
describe Solargraph::ComplexType do
  describe '#qualify_parts' do
    it 'rebuilds a union from what the block returns for each member' do
      type = described_class.parse('Foo', 'Bar')
      result = type.qualify_parts { |part| part.recreate(make_rooted: true) }
      expect(result.rooted_tags).to eq('::Foo, ::Bar')
    end

    it 'is nil when the block cannot resolve any one member' do
      type = described_class.parse('Foo', 'Bar')
      expect(type.qualify_parts { |part| part.name == 'Bar' ? nil : part }).to be_nil
    end

    it 'hands a single type to the block as itself' do
      type = described_class.parse('Foo').items.first
      expect(type.qualify_parts { |part| [part] }).to eq([type])
    end
  end

  describe 'ApiMap::Constants#qualify_type' do
    let(:constants) do
      source_map = Solargraph::SourceMap.load_string(%(
        module Outer
          class Foo; end
          class Bar; end
        end
      ), 'test.rb')
      Solargraph::ApiMap::Constants.new(Solargraph::ApiMap::Store.new(source_map.pins))
    end

    it 'qualifies every member of a union' do
      type = constants.qualify_type(described_class.parse('Foo', 'Bar'), 'Outer')
      expect(type.rooted_tags).to eq('::Outer::Foo, ::Outer::Bar')
    end

    it 'leaves members that name no constant as they are' do
      type = constants.qualify_type(described_class.parse('Foo', 'nil', 'self'), 'Outer')
      expect(type.rooted_tags).to eq('::Outer::Foo, nil, self')
    end

    it 'is nil when a member does not resolve' do
      expect(constants.qualify_type(described_class.parse('Foo', 'Missing'), 'Outer')).to be_nil
    end
  end
end
