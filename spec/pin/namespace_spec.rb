# frozen_string_literal: true

describe Solargraph::Pin::Namespace do
  it 'handles long namespaces' do
    pin = described_class.new(closure: described_class.new(name: 'Foo'), name: 'Bar')
    expect(pin.path).to eq('Foo::Bar')
  end

  it 'has class scope' do
    Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    pin = described_class.new(name: 'Foo')
    expect(pin.context.scope).to eq(:class)
  end

  it 'is a kind of namespace/class/module' do
    pin1 = described_class.new(name: 'Foo')
    expect(pin1.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CLASS)
    pin2 = described_class.new(name: 'Foo', type: :module)
    expect(pin2.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::MODULE)
  end

  it 'handles nested namespaces inside closures' do
    pin = described_class.new(closure: described_class.new(name: 'Foo'), name: 'Bar::Baz')
    expect(pin.namespace).to eq('Foo::Bar')
    expect(pin.name).to eq('Baz')
    expect(pin.path).to eq('Foo::Bar::Baz')
  end

  it 'uses @param tags as generic type parameters' do
    pin = described_class.new(name: 'Foo', comments: '@generic GenericType')
    expect(pin.generics).to eq(['GenericType'])
    expect(pin.to_rbs).to eq('class ::Foo[GenericType]')
  end

  it 'prefers the YARD pin type when combining with a disagreeing RBS pin' do
    rbs_pin = described_class.new(name: 'Foo', type: :class, source: :rbs)
    yard_pin = described_class.new(name: 'Foo', type: :module, source: :yardoc)
    expect(rbs_pin.combine_with(yard_pin).type).to eq(:module)
  end

  it 'falls back to its own type when neither disagreeing pin is from YARD' do
    rbs_pin1 = described_class.new(name: 'Foo', type: :class, source: :rbs)
    rbs_pin2 = described_class.new(name: 'Foo', type: :module, source: :rbs)
    expect(rbs_pin1.combine_with(rbs_pin2).type).to eq(:class)
  end
end
