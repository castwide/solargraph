# frozen_string_literal: true

# A minimal test double for a hypothetical second Typeset subclass - an
# intersection-equivalent, standing in for the not-yet-built
# Typedef::Intersection. Deliberately does not override any of the four
# methods Typeset only documents as abstract stubs (nullable?, to_s,
# to_s_for_complex_type, to_complex_type), to prove they are NOT inherited
# - only Typeset's real shared methods are.
class TypesetSpecConjunction < Solargraph::Typedef::Typeset
end

describe Solargraph::Typedef::Typeset do
  let(:string_type) { Solargraph::Typedef::Concrete.new(Solargraph::Typedef::Path.new('String', rooted: true)) }
  let(:array_type) { Solargraph::Typedef::Concrete.new(Solargraph::Typedef::Path.new('Array', rooted: true)) }
  let(:conjunction) { TypesetSpecConjunction.new([string_type, array_type]) }

  describe 'a subclass that overrides nothing' do
    it 'inherits the well-formedness predicates' do
      expect(conjunction).to be_rooted
      expect(conjunction).to be_resolved
      expect(conjunction).to be_expanded
    end

    it 'inherits the generics-completeness predicates' do
      expect(conjunction).not_to be_any_generic
      expect(conjunction).not_to be_all_generic
    end

    it 'inherits flat_types' do
      expect(conjunction.flat_types).to eq([string_type, array_type])
    end

    it 'inherits extract_generics' do
      expect(conjunction.extract_generics(conjunction)).to eq({})
    end

    it 'inherits resolve_rooted and builds the same subclass via self.class.new' do
      api_map = Solargraph::ApiMap.new
      resolved = conjunction.resolve_rooted(api_map, [''])
      expect(resolved).to be_a(TypesetSpecConjunction)
      expect(resolved).to be_rooted
    end

    it 'inherits expand and builds the same subclass via self.class.new' do
      expanded = conjunction.expand({})
      expect(expanded).to be_a(TypesetSpecConjunction)
      expect(expanded.types.map(&:to_s)).to eq(%w[String Array])
    end

    # Typeset only documents nullable?, to_s_for_complex_type, and
    # to_complex_type via @!method stubs - the same abstract-interface
    # pattern Solargraph::Type itself uses. A subclass that doesn't
    # override one gets no implementation at all, so calling it raises
    # NoMethodError rather than silently falling back to Union's OR logic.
    it 'does not inherit nullable?' do
      expect { conjunction.nullable? }.to raise_error(NoMethodError)
    end

    it 'does not inherit to_s_for_complex_type' do
      expect { conjunction.to_s_for_complex_type }.to raise_error(NoMethodError)
    end

    it 'does not inherit to_complex_type' do
      expect { conjunction.to_complex_type }.to raise_error(NoMethodError)
    end

    # to_s can't be tested the same way: Object#to_s is a real inherited
    # method with no override needed to avoid NoMethodError, so a subclass
    # that skips it still responds - just with Object's default
    # #<TypesetSpecConjunction:0x...> instead of the joined-branches
    # rendering Union and a future Intersection each provide.
    it 'does not inherit a joined-branches to_s' do
      expect(conjunction.to_s).not_to eq('String | Array')
    end
  end
end
