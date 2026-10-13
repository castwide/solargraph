# frozen_string_literal: true

# #void?, #undefined? and #defined? each ask whether a type carries any
# usable information. A union member that carries none decides for the
# whole union, because a value of the union may be that member.
describe Solargraph::ComplexType do
  describe '#void?' do
    it 'is true for a lone void type' do
      expect(described_class.parse('void').void?).to be true
    end

    it 'is false when no member is void' do
      expect(described_class.parse('Foo', 'Bar').void?).to be false
    end

    it 'is true when the first member is void' do
      expect(described_class.parse('void', 'Foo').void?).to be true
    end

    it 'is true when a later member is void' do
      expect(described_class.parse('Foo', 'void').void?).to be true
    end
  end

  describe '#undefined?' do
    it 'is true for a lone undefined type' do
      expect(described_class.parse('undefined').undefined?).to be true
    end

    it 'is false when no member is undefined' do
      expect(described_class.parse('Foo', 'Bar').undefined?).to be false
    end

    it 'is false for a union whose only empty member is void' do
      expect(described_class.parse('Foo', 'void').undefined?).to be false
    end

    it 'is true when any member is undefined, which also collapses the union' do
      type = described_class.parse('Foo', 'undefined')
      expect(type.undefined?).to be true
      expect(type.items.length).to eq(1)
    end

    it 'is false for the empty union, which is the bottom type' do
      expect(described_class.parse.undefined?).to be false
    end
  end

  describe '#defined?' do
    it 'is the negation of #undefined?' do
      %w[void undefined Foo].each do |tag|
        type = described_class.parse(tag)
        expect(type.defined?).to be(!type.undefined?)
      end
    end

    it 'is true for a union of named types' do
      expect(described_class.parse('Foo', 'Bar').defined?).to be true
    end

    it 'is true for a union carrying a void member' do
      expect(described_class.parse('Foo', 'void').defined?).to be true
    end

    it 'is false for a lone undefined type' do
      expect(described_class.parse('undefined').defined?).to be false
    end

    it 'is true for the empty union, which is a determined type' do
      expect(described_class.parse.defined?).to be true
    end
  end
end
