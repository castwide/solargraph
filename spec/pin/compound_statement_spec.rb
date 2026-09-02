# frozen_string_literal: true

describe Solargraph::Pin::CompoundStatement do
  # Every pin built through Region-threaded node processors still gets
  # an explicit `closure:`, so `Pin::Base#closure` returns the stored
  # value, not the derived one - the derivation only kicks in as a
  # fallback. These specs check the two would agree anyway, so a
  # future node processor that updates one threading (closure: or
  # compound_statement:) without the other gets caught here instead
  # of silently drifting.
  def derive_closure pin
    cs = pin.compound_statement
    cs = cs.compound_statement while cs && !cs.is_a?(Solargraph::Pin::Closure)
    cs
  end

  it 'agrees with the stored closure for compound statements nested in a method, if, and while' do
    source_map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(flag)
          if flag
            while flag
              local = 1
            end
          end
        end
      end
    ))

    compound_statement_pins = source_map.pins.select { |pin| pin.is_a?(described_class) }
    expect(compound_statement_pins).not_to be_empty

    compound_statement_pins.each do |pin|
      expect(derive_closure(pin)).to eq(pin.closure), "mismatch for #{pin.inspect}"
    end
  end

  it 'agrees with the stored closure for compound statements nested in a block' do
    source_map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
          [1].each do |i|
            if i
              local = i
            end
          end
        end
      end
    ))

    compound_statement_pins = source_map.pins.select { |pin| pin.is_a?(described_class) }
    expect(compound_statement_pins).not_to be_empty

    compound_statement_pins.each do |pin|
      expect(derive_closure(pin)).to eq(pin.closure), "mismatch for #{pin.inspect}"
    end
  end

  it 'derives the enclosing method as closure for a bare CompoundStatement built only with compound_statement:' do
    source_map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
          1
        end
      end
    ))
    method_pin = source_map.pins.find { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.name == 'bar' }

    bare_pin = described_class.new(
      location: method_pin.location,
      compound_statement: method_pin,
      source: :parser
    )

    expect(bare_pin.closure).to eq(method_pin)
  end

  describe '#combine_with' do
    let(:earlier_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(1, 0, 3, 0)) }
    let(:later_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 0, 7, 0)) }

    it 'prefers the compound_statement with the earlier location' do
      earlier_cs = described_class.new(location: earlier_location, source: :parser)
      later_cs = described_class.new(location: later_location, source: :parser)
      pin1 = described_class.new(location: earlier_location, compound_statement: earlier_cs, source: :parser)
      pin2 = described_class.new(location: later_location, compound_statement: later_cs, source: :parser)

      expect(pin1.combine_with(pin2).compound_statement).to eq(earlier_cs)
      expect(pin2.combine_with(pin1).compound_statement).to eq(earlier_cs)
    end

    it 'prefers the compound_statement with a location when the other has none' do
      cs_no_location = described_class.new(location: nil, source: :parser)
      cs_with_location = described_class.new(location: later_location, source: :parser)
      pin1 = described_class.new(location: earlier_location, compound_statement: cs_no_location, source: :parser)
      pin2 = described_class.new(location: earlier_location, compound_statement: cs_with_location, source: :parser)

      expect(pin1.combine_with(pin2).compound_statement).to eq(cs_with_location)
      expect(pin2.combine_with(pin1).compound_statement).to eq(cs_with_location)
    end

    it 'prefers a non-nil compound_statement over a nil one' do
      cs = described_class.new(location: earlier_location, source: :parser)
      pin1 = described_class.new(location: earlier_location, compound_statement: nil, source: :parser)
      pin2 = described_class.new(location: earlier_location, compound_statement: cs, source: :parser)

      expect(pin1.combine_with(pin2).compound_statement).to eq(cs)
      expect(pin2.combine_with(pin1).compound_statement).to eq(cs)
    end
  end
end
