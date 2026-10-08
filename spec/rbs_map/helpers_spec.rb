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

  it 'combines a method with the RBS alias of the same path' do
    yard_pin = Solargraph::Pin::Method.new(closure: closure, name: 'original_dup', scope: :instance, comments: '@return [Foo]',
                                           source: :yardoc, type_location: location)
    rbs_pins = [
      closure,
      Solargraph::Pin::Method.new(closure: closure, name: 'dup', scope: :instance, comments: '@return [Foo]',
                                  source: :rbs, type_location: location),
      Solargraph::Pin::MethodAlias.new(closure: closure, name: 'original_dup', original: 'dup',
                                       comments: '@return [Foo]', source: :rbs, type_location: location)
    ]
    allow(Solargraph).to receive(:asserts_on?).and_return(true)

    combined = described_class.combine([yard_pin], rbs_pins).find { |pin| pin.path == 'Foo#original_dup' }

    expect(combined.return_type.to_s).to eq('Foo')
  end
end
