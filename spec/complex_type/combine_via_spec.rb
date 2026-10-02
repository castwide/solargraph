# frozen_string_literal: true

# #combine_via pairs two types up member by member. The block below
# states the same rule Pin::Base#combine_return_type passes in, so
# these are the results that method produces.
describe Solargraph::ComplexType do
  let(:self_tags) { 'Foo' }

  def intersection *tags
    Solargraph::ComplexType::UniqueType::Intersection.new(tags.map { |tag| Solargraph::ComplexType.parse(tag) })
  end

  def combine left, right
    left.combine_via(right) do |mine, theirs|
      if mine.rooted_tags == theirs.rooted_tags || (mine.selfy? && theirs.rooted_tags == self_tags)
        mine
      elsif theirs.selfy? && mine.rooted_tags == self_tags
        theirs
      else
        Solargraph::ComplexType.union(mine, theirs)
      end
    end
  end

  describe '.union' do
    it 'returns a repeated type as itself rather than as a union of one' do
      type = described_class.parse('A').items.first
      expect(described_class.union(type, type)).to be(type)
    end
  end

  describe '#combine_via' do
    it 'matches the members both sides carry whatever order they appear in' do
      expect(combine(described_class.parse('A, B'), described_class.parse('B, A')).rooted_tags).to eq('A, B')
    end

    it 'zips up the members left over once the shared ones are matched' do
      expect(combine(described_class.parse('A, C'), described_class.parse('D, A')).rooted_tags).to eq('A, C, D')
    end

    it 'hands the whole remainder of the longer side to the last member of the shorter' do
      expect(combine(described_class.parse('A, B, C, D'), described_class.parse('A, E, F')).rooted_tags)
        .to eq('A, B, E, C, D, F')
    end

    it 'sets a lone member on the right against the whole union on the left' do
      expect(combine(described_class.parse('A, B'), described_class.parse('A')).rooted_tags).to eq('A, B')
    end

    it 'sets a lone member on the left against the whole union on the right' do
      expect(combine(described_class.parse('A'), described_class.parse('B, C')).rooted_tags).to eq('A, B, C')
    end

    it 'keeps a member the other side ran out of counterparts for' do
      expect(combine(described_class.parse('String, nil'), described_class.parse('String, Symbol, nil')).rooted_tags)
        .to eq('String, nil, Symbol')
    end

    it 'reads a declaration naming both self and the enclosing class as self' do
      expect(combine(described_class.parse('self'), described_class.parse('Foo')).rooted_tags).to eq('self')
    end

    it 'reads it the same way with the enclosing class named first' do
      expect(combine(described_class.parse('Foo'), described_class.parse('self')).rooted_tags).to eq('self')
    end

    context 'with an intersection on the left' do
      it 'unions with a type that has no conjuncts to line up against' do
        expect(combine(intersection('X', 'Y'), described_class.parse('Z')).rooted_tags).to eq('X & Y, Z')
      end

      it 'stays unchanged when the other intersection carries the same conjuncts' do
        expect(combine(intersection('A', 'B'), intersection('A', 'B')).rooted_tags).to eq('A & B')
      end

      it 'widens only the conjunct the two intersections disagree on' do
        expect(combine(intersection('A', 'B'), intersection('A', 'C')).rooted_tags).to eq('A & [B, C]')
      end
    end
  end
end
