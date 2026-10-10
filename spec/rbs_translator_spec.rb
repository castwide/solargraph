# frozen_string_literal: true

require 'rbs'

describe Solargraph::RbsTranslator do
  describe '.build_unique_type' do
    # No caller in this repo; it is public API a plugin can reach.
    def class_instance name
      RBS::Types::ClassInstance.new(name: RBS::TypeName.parse(name), args: [], location: nil)
    end

    it 'builds a rooted list-parameterized type from a bare type name' do
      type = described_class.build_unique_type(RBS::TypeName.parse('::String'))
      expect(type.tag).to eq('String')
      expect(type).to be_rooted
      expect(type.parameters_type).to be(:list)
    end

    it 'builds a key-value type when Hash is given exactly two arguments' do
      type = described_class.build_unique_type(RBS::TypeName.parse('::Hash'),
                                               [class_instance('::Symbol'), class_instance('::Integer')])
      expect(type.tag).to eq('Hash{Symbol => Integer}')
      expect(type.parameters_type).to be(:hash)
    end

    it 'interns what it builds, so two equal results share one object' do
      first = described_class.build_unique_type(RBS::TypeName.parse('::String'))
      second = described_class.build_unique_type(RBS::TypeName.parse('::String'))
      expect(first).to be(second)
    end
  end
end
