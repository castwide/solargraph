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

    it 'combines many same-path pins without timing out' do
      # Smoke test for the concern that originally motivated
      # castwide/solargraph#1186 ("Stub combine_same_type_arity_signatures",
      # merged as a stopgap for "an infinite loop bug in Ruby 3.x") and
      # castwide/solargraph#1195 ("Limit pin combination to doc maps",
      # which removed this combining logic from Store#get_methods
      # entirely). The "infinite loop" was later diagnosed as an
      # exponential blowup in Pin::Method#combine_same_type_arity_signatures
      # and fixed in castwide/solargraph#1238.
      #
      # This does NOT reproduce that specific bug: these hand-written
      # single-type parameters all collapse to the same
      # Pin::Parameter#type_arity_decl bucket (a separate, still-open
      # gap - it groups by union member *count*, not the actual
      # types), so they hit the ">10" bail-out before ever reaching
      # the code path #1238 fixed. #1238's own regression spec
      # (spec/pin/method_spec.rb "combines many non-mergeable
      # same-type-arity signatures without exponential blowup") is
      # the precise guard for that bug, exercising
      # combine_same_type_arity_signatures directly with signatures
      # engineered to never merge. This spec instead just confirms
      # Store#get_methods' combination of many real same-path pins,
      # as this PR adds, completes quickly rather than hanging.
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
      # The real regression is combinatorial blowup, not the exact
      # merge outcome - bound the result size rather than pin down
      # merge semantics unrelated to this concern.
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
