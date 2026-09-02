# frozen_string_literal: true

require 'timeout'

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
      # A combined alias pin can't be traced back to its original
      # target, which #resolve_method_alias needs to work.
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

    it 'does not combine two delegated methods sharing a path' do
      # DelegatedMethod#initialize requires exactly one of :method /
      # :receiver, so a merged pin can't hold both delegation targets.
      closure = Solargraph::Pin::Namespace.new(name: 'Foo', closure: Solargraph::Pin::ROOT_PIN, type: :class)
      delegated = lambda do |receiver_name|
        chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new(receiver_name, nil)])
        Solargraph::Pin::DelegatedMethod.new(closure: closure, scope: :instance, name: 'bar', receiver: chain)
      end
      store = described_class.new([closure, delegated.call('one'), delegated.call('two')])
      pins = []
      expect { pins = store.get_methods('Foo', scope: :instance) }.not_to raise_error
      bar_pins = pins.select { |p| p.name == 'bar' }
      expect(bar_pins.length).to eq(2)
      expect(bar_pins).to all(be_an_instance_of(Solargraph::Pin::DelegatedMethod))
    end

    it 'combines many same-path pins without timing out' do
      maps = (1..30).map do |i|
        Solargraph::SourceMap.load_string(%(
          class Foo
            # @param other [Type#{i}]
            # @return [Type#{i}]
            def bar(other); end
          end
        ), "source#{i}.rb")
      end
      store = nil
      Timeout.timeout(5) { store = described_class.new(maps.flat_map(&:pins)) }

      result = nil
      Timeout.timeout(5) { result = store.get_methods('Foo', scope: :instance) }

      bar_pins = result.select { |p| p.name == 'bar' }
      expect(bar_pins.length).to eq(1)
      # Regression is combinatorial blowup, not exact merge outcome -
      # bound the result size rather than pin exact merge semantics.
      expect(bar_pins.first.signatures.length).to be <= maps.length
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
