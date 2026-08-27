# frozen_string_literal: true

# A minimal test double for a hypothetical third Element kind. Not a real
# feature - just enough to prove a new kind can subclass Element and work
# at an existing call site (Typeset's own construction and predicates)
# without any change to Typeset or Type.
#
# Represents an intersection-equivalent: "every one of these conjuncts
# must hold at once" - the composite kind Problem 1's background names as
# the concrete example of a future third kind Typedef doesn't have yet.
class TypedefElementSpecConjunction < Solargraph::Typedef::Element
  attr_reader :conjuncts

  # @param conjuncts [Array<Solargraph::Typedef::Element>]
  def initialize conjuncts
    super()
    @conjuncts = conjuncts
  end

  def expand named_values
    self.class.new(conjuncts.map { |c| c.expand(named_values) })
  end

  def resolve_rooted api_map, gates
    self.class.new(conjuncts.map { |c| c.resolve_rooted(api_map, gates) })
  end

  # @return [Hash]
  def extract_generics _other
    {}
  end

  def flat_types
    conjuncts.flat_map(&:flat_types)
  end

  def to_complex_type
    Solargraph::ComplexType.new(conjuncts.map(&:to_complex_type))
  end

  def to_s
    conjuncts.join(' & ')
  end

  def to_s_for_complex_type
    conjuncts.map(&:to_s_for_complex_type).join(', ')
  end

  def rooted?
    conjuncts.all?(&:rooted?)
  end

  def resolved?
    conjuncts.all?(&:resolved?)
  end

  def expanded?
    conjuncts.all?(&:expanded?)
  end

  def nullable?
    conjuncts.any?(&:nullable?)
  end

  def any_generic?
    conjuncts.any?(&:any_generic?)
  end

  def all_generic?
    conjuncts.all?(&:any_generic?)
  end
end

# Every method Element stubs, minus the ones RSpec already exercises via
# a predicate matcher (any_generic?/all_generic?/rooted?/resolved?/
# expanded?/nullable? are covered per-kind by their own describe blocks
# elsewhere in this directory) - this just proves each kind answers the
# full protocol at all, which is what lets a caller hold "some Element"
# without knowing the concrete class.
shared_examples 'a Typedef element' do
  it 'is an Element' do
    expect(subject).to be_a(Solargraph::Typedef::Element)
  end

  it 'answers to_s' do
    expect(subject.to_s).to be_a(String)
  end

  it 'answers to_s_for_complex_type' do
    expect(subject.to_s_for_complex_type).to be_a(String)
  end

  it 'answers to_complex_type' do
    expect(subject.to_complex_type).to be_a(Solargraph::ComplexType)
  end

  it 'answers flat_types' do
    expect(subject.flat_types).to be_an(Array)
  end

  it 'answers expand' do
    expect(subject.expand({})).to be_a(Solargraph::Typedef::Element)
  end

  it 'answers the boolean predicates' do
    expect(subject.rooted?).to be(true).or be(false)
    expect(subject.resolved?).to be(true).or be(false)
    expect(subject.expanded?).to be(true).or be(false)
    expect(subject.nullable?).to be(true).or be(false)
    expect(subject.any_generic?).to be(true).or be(false)
    expect(subject.all_generic?).to be(true).or be(false)
  end
end

describe Solargraph::Typedef::Element do
  describe Solargraph::Typedef::Type do
    subject { described_class.new(Solargraph::Typedef.tokenize('String')) }

    it_behaves_like 'a Typedef element'
  end

  describe Solargraph::Typedef::Tuple do
    subject { described_class.new(Solargraph::Typedef.tokenize('Array'), Solargraph::Typedef.tokenize('String')) }

    it_behaves_like 'a Typedef element'
  end

  describe Solargraph::Typedef::Typeset do
    subject { described_class.new([Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))]) }

    it_behaves_like 'a Typedef element'
  end

  describe TypedefElementSpecConjunction do
    subject do
      types = [Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String')),
               Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Comparable'))]
      described_class.new(types)
    end

    it_behaves_like 'a Typedef element'
  end

  describe 'a future third kind subclassing Element directly' do
    let(:string_type) { Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String')) }
    let(:comparable_type) { Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Comparable')) }
    let(:conjunction) { TypedefElementSpecConjunction.new([string_type, comparable_type]) }

    it 'passes through Typeset.new unmodified and participates in its predicates' do
      typeset = Solargraph::Typedef::Typeset.new([conjunction, Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Integer'))])

      expect(typeset.types).to include(conjunction)
      expect(typeset.to_s).to eq('String & Comparable | Integer')
      # Neither Path defaults to rooted, so the conjunction - and the
      # typeset it's mixed into - correctly report unrooted without
      # Typeset#rooted? ever being told this kind exists.
      expect(conjunction.rooted?).to be(false)
      expect(typeset.rooted?).to be(false)
    end
  end
end
