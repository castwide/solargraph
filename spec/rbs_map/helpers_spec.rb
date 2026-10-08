# frozen_string_literal: true

describe Solargraph::RbsMap::Helpers do
  let(:location) { Solargraph::Location.new('foo.rbs', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:closure) { Solargraph::Pin::Namespace.new(name: 'Foo', type: :class, source: :rbs, type_location: location) }

  # @param name [String]
  # @param type [String]
  # @param source [Symbol]
  # @return [Solargraph::Pin::Method]
  def method_pin name, type, source: :rbs
    typed = Solargraph::Pin::Method.new(closure: closure, name: name, scope: :instance,
                                        source: source, type_location: location,
                                        comments: "@overload #{name}(other)\n  @param other [#{type}]\n  @return [#{type}]")
    Solargraph::Pin::Method.new(closure: closure, name: name, scope: :instance, comments: 'Subtract.',
                                signatures: typed.signatures, source: source, type_location: location)
  end

  it 'keeps the signatures of pins that share only their documentation' do
    combined = described_class.combine_method_pins(method_pin('-', 'BigDecimal'), method_pin('-', 'Integer'))

    types = combined.signatures.map { |sig| sig.parameters.first.return_type.to_s }
    expect(types).to contain_exactly('BigDecimal', 'Integer')
  end
end
