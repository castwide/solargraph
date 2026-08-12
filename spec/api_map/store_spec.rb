# frozen_string_literal: true

describe Solargraph::ApiMap::Store do
  it 'indexes multiple pinsets' do
    foo_pin = Solargraph::Pin::Namespace.new(name: 'Foo')
    bar_pin = Solargraph::Pin::Namespace.new(name: 'Bar')
    store = described_class.new([foo_pin], [bar_pin])

    expect(store.get_path_pins('Foo')).to eq([foo_pin])
    expect(store.get_path_pins('Bar')).to eq([bar_pin])
  end

  it 'indexes empty pinsets' do
    foo_pin = Solargraph::Pin::Namespace.new(name: 'Foo')

    store = described_class.new([], [foo_pin])
    expect(store.get_path_pins('Foo')).to eq([foo_pin])
  end

  it 'updates existing pinsets' do
    foo_pin = Solargraph::Pin::Namespace.new(name: 'Foo')
    bar_pin = Solargraph::Pin::Namespace.new(name: 'Bar')
    baz_pin = Solargraph::Pin::Namespace.new(name: 'Baz')
    store = described_class.new([foo_pin], [bar_pin])
    store.update([foo_pin], [baz_pin])

    expect(store.get_path_pins('Foo')).to eq([foo_pin])
    expect(store.get_path_pins('Baz')).to eq([baz_pin])
    expect(store.get_path_pins('Bar')).to be_empty
  end

  it 'updates new pinsets' do
    foo_pin = Solargraph::Pin::Namespace.new(name: 'Foo')
    bar_pin = Solargraph::Pin::Namespace.new(name: 'Bar')
    store = described_class.new([foo_pin])
    store.update([foo_pin], [bar_pin])

    expect(store.get_path_pins('Foo')).to eq([foo_pin])
    expect(store.get_path_pins('Bar')).to eq([bar_pin])
  end

  it 'updates empty stores' do
    foo_pin = Solargraph::Pin::Namespace.new(name: 'Foo')
    bar_pin = Solargraph::Pin::Namespace.new(name: 'Bar')
    store = described_class.new
    store.update([foo_pin, bar_pin])

    expect(store.get_path_pins('Foo')).to eq([foo_pin])
    expect(store.get_path_pins('Bar')).to eq([bar_pin])
  end

  describe '#get_methods' do
    it 'combines pins for the same method path from different sources' do
      plain_impl = Solargraph::SourceMap.load_string(%(
        class Foo
          def bar; end
        end
      ), 'plain.rb')
      override = Solargraph::SourceMap.load_string(%(
        class Foo
          # @return [String]
          def bar; end
        end
      ), 'override.rb')
      store = described_class.new(plain_impl.pins + override.pins)
      pins = store.get_methods('Foo', scope: :instance).select { |p| p.name == 'bar' }
      expect(pins.length).to eq(1)
      expect(pins.first.return_type.tag).to eq('String')
    end

    it 'does not combine a method alias with a regular method sharing its path' do
      # Combining an alias pin with a non-alias pin at the same path
      # previously produced a `:combined` pin that couldn't be
      # resolved back to its original target, raising under
      # SOLARGRAPH_ASSERTS=on.
      regular = Solargraph::SourceMap.load_string(%(
        class Foo
          def bar; end
        end
      ), 'regular.rb')
      aliased = Solargraph::SourceMap.load_string(%(
        class Foo
          def baz; end
          alias bar baz
        end
      ), 'aliased.rb')
      store = described_class.new(regular.pins + aliased.pins)
      pins = []
      expect { pins = store.get_methods('Foo', scope: :instance) }.not_to raise_error
      bar_pins = pins.select { |p| p.name == 'bar' }
      expect(bar_pins.length).to eq(2)
      expect(bar_pins).to include(an_instance_of(Solargraph::Pin::MethodAlias))
    end
  end

  # @todo This will become #get_superclass
  describe '#get_superclass' do
    it 'returns simple superclasses' do
      map = Solargraph::SourceMap.load_string(%(
        class Foo; end
        class Bar < Foo; end
      ), 'test.rb')
      store = described_class.new(map.pins)
      ref = store.get_superclass('Bar')
      expect(ref.name).to eq('Foo')
    end

    it 'returns Boolean superclass' do
      store = described_class.new
      ref = store.get_superclass('TrueClass')
      expect(ref.name).to eq('Boolean')
    end

    it 'maps core Errno classes' do
      map = Solargraph::RbsMap::CoreMap.new
      store = described_class.new(map.pins)
      Errno.constants.each do |const|
        pin = store.get_path_pins("Errno::#{const}").first
        expect(pin).to be_a(Solargraph::Pin::Namespace)
        superclass = store.get_superclass(pin.path)
        expect(superclass.name).to eq('::SystemCallError')
        expect(store.constants.dereference(superclass)).to eq('SystemCallError')
      end
    end
  end
end
