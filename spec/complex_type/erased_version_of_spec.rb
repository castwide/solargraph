# frozen_string_literal: true

# #erased_version_of? asks whether the receiver is the same type as the
# argument with its parameters dropped, so Pin::Base#combine_return_type
# can keep the parameterized one of a pair. The receiver is the erased
# side, which makes the question asymmetric.
describe Solargraph::ComplexType do
  def erased_of? mine, theirs
    described_class.parse(mine).erased_version_of?(described_class.parse(theirs))
  end

  context 'with named types' do
    it 'is true for a parameterless type against its parameterized form' do
      expect(erased_of?('Array', 'Array<String>')).to be true
    end

    it 'is false in the other direction' do
      expect(erased_of?('Array<String>', 'Array')).to be false
    end

    it 'is true for two identical parameterless types' do
      expect(erased_of?('String', 'String')).to be true
    end

    it 'is false for different names' do
      expect(erased_of?('String', 'Integer')).to be false
    end
  end

  context 'with intersections' do
    it 'is true when every conjunct is the erased form of its counterpart' do
      expect(erased_of?('Array & Comparable', 'Array<String> & Comparable')).to be true
    end

    it 'is false in the other direction' do
      expect(erased_of?('Array<String> & Comparable', 'Array & Comparable')).to be false
    end

    it 'is false when the conjunct counts differ' do
      expect(erased_of?('Array & Comparable', 'Array & Comparable & Enumerable')).to be false
    end

    # Neither is the other with its parameters dropped: one names a single
    # type and the other names several at once.
    it 'is false against a named type' do
      expect(erased_of?('Array & Comparable', 'Array')).to be false
    end

    it 'is false when the named type is the receiver' do
      expect(erased_of?('Array', 'Array & Comparable')).to be false
    end
  end
end
