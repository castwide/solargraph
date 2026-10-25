# frozen_string_literal: true

describe Solargraph::Type do
  # Public methods every implementation shares that the contract
  # deliberately leaves out.
  shared_not_declared = [
    # Its semantics are still being settled by the intersection type work
    # (castwide/solargraph#1229), so callers keep naming the concrete class.
    :intersect_with
  ].freeze

  # Contract methods ComplexType answers through method_missing, which
  # forwards them to its first member, or answers nil when it has none.
  delegated_to_first_member = %i[
    duck_type? erased_variance namespace_type rooted_namespace rooted_tag scope tag value_types
  ].freeze

  # The contract is written as @!method directives, so read it the way
  # Solargraph reads any source file.
  let(:contract) do
    path = File.expand_path('../lib/solargraph/type.rb', __dir__)
    Solargraph::SourceMap.load(path).pins
                         .select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.path.start_with?('Solargraph::Type#') }
                         .map { |pin| pin.name.to_sym }
  end

  # Naming the known implementations loads them; ObjectSpace finds any other
  let(:implementations) do
    known = [Solargraph::ComplexType, Solargraph::ComplexType::UniqueType]
    known | ObjectSpace.each_object(Class).select { |klass| klass < described_class }
  end

  # Where a method comes from when no implementation defines it
  let(:fallback_owners) { [described_class, Object, Kernel, BasicObject] }

  it 'declares methods' do
    expect(contract).to include(:conforms_to?, :to_s)
  end

  it 'is implemented by ComplexType and UniqueType' do
    expect(implementations).to all(be < described_class)
  end

  it 'is defined in full by every implementation' do
    missing = implementations.to_h do |klass|
      [klass, contract.reject do |name|
        klass.public_method_defined?(name) && !fallback_owners.include?(klass.instance_method(name).owner)
      end]
    end
    expected = implementations.to_h { |klass| [klass, []] }
    expected[Solargraph::ComplexType] = delegated_to_first_member
    expect(missing.transform_values(&:sort)).to eq(expected.transform_values(&:sort))
  end

  it 'answers the methods ComplexType delegates to its first member' do
    type = Solargraph::ComplexType.parse('String, Integer')
    expect(delegated_to_first_member).to all(satisfy { |name| type.respond_to?(name) })
  end

  it 'declares every public method the implementations share' do
    shared = implementations.map(&:public_instance_methods).reduce(:&) - Object.public_instance_methods
    expect(shared - contract - shared_not_declared).to be_empty
  end

  it 'leaves out only methods the implementations share' do
    shared = implementations.map(&:public_instance_methods).reduce(:&)
    expect(shared_not_declared - shared).to be_empty
    expect(shared_not_declared & contract).to be_empty
  end
end
