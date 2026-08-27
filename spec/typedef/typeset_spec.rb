# frozen_string_literal: true

describe Solargraph::Typedef::Typeset do
  describe '.new' do
    it 'accepts multiple types' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('String'))
      typeset = described_class.new([type1, type2])
      expect(typeset.to_s).to eq('Array | String')
    end

    it 'reduces to unique types' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('String'))
      type3 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('Array'))
      typeset = described_class.new([type1, type2, type3])
      expect(typeset.to_s).to eq('Array | String')
    end
  end

  describe '#to_complex_type' do
    it 'converts to complex types' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('String'))
      typeset = described_class.new([type1, type2])
      complex_type = typeset.to_complex_type
      expect(complex_type).to be_a(Solargraph::ComplexType)
      expect(complex_type.to_s).to eq('Array, String')
    end
  end

  describe '#expand' do
    it 'expands all types' do
      type1 = Solargraph::ComplexType.parse('Array<generic<T>>').to_typedef_typeset
      type2 = Solargraph::ComplexType.parse('Set<generic<T>>').to_typedef_typeset
      typeset = described_class.new([type1, type2])
      named_values = { 'generic<T>' => 'String' }
      expanded = typeset.expand(named_values)
      expect(expanded.to_s).to eq('Array[String] | Set[String]')
    end
  end

  describe '#any_generic?' do
    it 'is true if any branch is generic' do
      typeset = Solargraph::ComplexType.parse('Array<generic<T>>, String').to_typedef_typeset
      expect(typeset).to be_any_generic
    end

    it 'is false if no branch is generic' do
      typeset = Solargraph::ComplexType.parse('Array<String>, String').to_typedef_typeset
      expect(typeset).not_to be_any_generic
    end
  end

  describe '#all_generic?' do
    it 'is true only if every branch is generic' do
      all_generic = Solargraph::ComplexType.parse('generic<T>, generic<U>').to_typedef_typeset
      expect(all_generic).to be_all_generic
    end

    it 'is false if only some branches are generic' do
      mixed = Solargraph::ComplexType.parse('Array<generic<T>>, String').to_typedef_typeset
      expect(mixed).not_to be_all_generic
    end
  end

  describe '#rooted?' do
    it 'is true only if every branch is rooted' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef::Path.new('String', rooted: true))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef::Path.new('Array', rooted: true))
      typeset = described_class.new([type1, type2])
      expect(typeset).to be_rooted
    end

    it 'is false if any branch is unrooted' do
      rooted = Solargraph::Typedef::Unique.new(Solargraph::Typedef::Path.new('::String', rooted: true))
      unrooted = Solargraph::Typedef::Unique.new(Solargraph::Typedef::Path.new('Array', rooted: false))
      typeset = described_class.new([rooted, unrooted])
      expect(typeset).not_to be_rooted
    end
  end

  describe '#resolved?' do
    it 'is true only if every branch is resolved' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('nil'))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('undefined'))
      typeset = described_class.new([type1, type2])
      expect(typeset).to be_resolved
    end

    it 'is false if any branch is unresolved' do
      resolved = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('nil'))
      unresolved = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('foo'))
      typeset = described_class.new([resolved, unresolved])
      expect(typeset).not_to be_resolved
    end
  end

  describe '#expanded?' do
    it 'is true only if every branch is expanded' do
      type1 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('nil'))
      type2 = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('undefined'))
      typeset = described_class.new([type1, type2])
      expect(typeset).to be_expanded
    end

    it 'is false if any branch is unexpanded' do
      expanded = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('nil'))
      unexpanded = Solargraph::Typedef::Unique.new(Solargraph::Typedef.tokenize('foo'))
      typeset = described_class.new([expanded, unexpanded])
      expect(typeset).not_to be_expanded
    end
  end

  describe '#nullable?' do
    it 'returns true with a nil return type' do
      complex_type = Solargraph::ComplexType.parse('String, nil')
      typeset = complex_type.to_typedef_typeset
      expect(typeset).to be_nullable
    end

    it 'returns false without a nil return type' do
      complex_type = Solargraph::ComplexType.parse('String')
      typeset = complex_type.to_typedef_typeset
      expect(typeset).not_to be_nullable
    end
  end

  # Although these tests are for a ComplexType method, they're collected here
  # because they're specific to the Typedef library. They'll eventually get
  # deprecated along with the ComplexType library itself.
  describe 'ComplexType#to_typedef_typeset' do
    it 'handles complex types with hashes' do
      complex_type = Solargraph::ComplexType.parse('Hash{String => Integer}')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Hash[String, Integer]')
    end

    it 'handles complex types with hashes and non-hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Hash<String, Integer>')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Hash[String, Integer]')
    end

    it 'handles complex types with inline hashes' do
      complex_type = Solargraph::ComplexType.parse('Array<undefined>, Hash{String => undefined}, String, Integer')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Array[undefined] | Hash[String, undefined] | String | Integer')
    end

    it 'handles complex types with inline hashes and non-hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Array<undefined>, Hash<String, undefined>, String, Integer')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Array[undefined] | Hash[String, undefined] | String | Integer')
    end
  end
end
