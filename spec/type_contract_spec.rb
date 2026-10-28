# frozen_string_literal: true

describe Solargraph::Type do
  # The Typedef protocol, which ComplexType and UniqueType are not
  # expected to take on since the Typedef classes replace them.
  typedef_protocol = %i[
    all_generic? expanded? extract_generics flat_types resolve_rooted resolved?
    to_complex_type to_s_for_complex_type
  ].freeze

  # Methods lib/ calls on a type that the Typedef classes do not define
  # yet. Each one ported shrinks this list.
  not_yet_on_typedef = %i[
    == all_rooted? any_duck_type? conforms_to? downcast_to_literal_if_possible eql?
    erased_variance erased_version_of? hash namespaces nil_type? qualify reduce_class_type
    resolve_generics resolve_generics_from_context rooted_tags self_to_type selfy? tags
    to_rbs transform void? without_nil
  ].freeze

  # Contract methods ComplexType answers through method_missing, which
  # forwards them to its first member.
  delegated_to_first_member = %i[erased_variance].freeze

  # The contract is written as @!method directives, so read it the way
  # Solargraph reads any source file.
  let(:contract) do
    path = File.expand_path('../lib/solargraph/type.rb', __dir__)
    Solargraph::SourceMap.load(path).pins
                         .select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.path.start_with?('Solargraph::Type#') }
                         .map { |pin| pin.name.to_sym }
  end

  # Listed rather than found through ObjectSpace, which would also find
  # test doubles depending on load order. Type and Typedef::Typeset are
  # abstract.
  let(:implementations) do
    [
      Solargraph::ComplexType, Solargraph::ComplexType::UniqueType,
      Solargraph::Typedef::Concrete, Solargraph::Typedef::Tuple, Solargraph::Typedef::Union
    ]
  end

  # What each implementation does not define yet
  let(:expected_gaps) do
    {
      Solargraph::ComplexType => typedef_protocol + delegated_to_first_member,
      Solargraph::ComplexType::UniqueType => typedef_protocol,
      Solargraph::Typedef::Concrete => not_yet_on_typedef,
      Solargraph::Typedef::Tuple => not_yet_on_typedef,
      Solargraph::Typedef::Union => not_yet_on_typedef
    }
  end

  # Where a method comes from when no implementation defines it
  let(:fallback_owners) { [described_class, Object, Kernel, BasicObject] }

  it 'declares methods' do
    expect(contract).to include(:candidate_methods_from, :method_stack_pins, :qualify_parts, :order_nil_last,
                                :any_generic?)
  end

  it 'is implemented by every type class' do
    expect(implementations).to all(be < described_class)
  end

  it 'is defined by each implementation apart from its listed gaps' do
    gaps = implementations.to_h do |klass|
      [klass, contract.reject do |name|
        klass.public_method_defined?(name) && !fallback_owners.include?(klass.instance_method(name).owner)
      end.sort]
    end
    expect(gaps).to eq(expected_gaps.transform_values(&:sort))
  end

  it 'answers the methods ComplexType delegates to its first member' do
    type = Solargraph::ComplexType.parse('String, Integer')
    expect(delegated_to_first_member).to all(satisfy { |name| type.respond_to?(name) })
  end

  it 'lists only declared methods as gaps' do
    expect((typedef_protocol + not_yet_on_typedef) - contract).to be_empty
  end

  it 'declares every public method the implementations share' do
    shared = implementations.map(&:public_instance_methods).reduce(:&) - Object.public_instance_methods
    expect(shared - contract).to be_empty
  end
end
