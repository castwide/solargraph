# frozen_string_literal: true

describe Solargraph::Pin::Base, '#combine_with' do
  it 'combines return types with another method pin with same arity' do
    pin1 = Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [String]')
    pin2 = Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [Integer]')
    combined = pin1.combine_with(pin2)
    expect(combined.return_type.to_s).to eq('String, Integer')
  end

  it 'combines return types with another method without type parameters' do
    pending('logic being added to handle this case')
    pin1 = Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [Array<String>]')
    pin2 = Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [Array]')
    combined = pin1.combine_with(pin2)
    expect(combined.return_type.to_s).to eq('Array<String>')
  end

  context 'with dodgy return types' do
    let(:dodgy_location_pin) do
      range = Solargraph::Range.new(Solargraph::Position.new(1, 0), Solargraph::Position.new(1, 10))
      location = Solargraph::Location.new('/home/user/.rbenv/versions/3.1.7/lib/ruby/gems/3.1.0/gems' \
                                          '/activesupport-7.0.8.7/lib/active_support/core_ext/object' \
                                          '/conversions.rb',
                                          range)
      Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [Object]',
                                  location: location)
    end

    let(:normal_pin) { Solargraph::Pin::Method.new(name: 'foo', parameters: [], comments: '@return [self]') }

    it 'combines a dodgy return type with a valid one' do
      combined = dodgy_location_pin.combine_with(normal_pin)
      expect(combined.return_type.to_s).to eq('self')
    end

    it 'combines a valid return type with a dodgy one' do
      combined = normal_pin.combine_with(dodgy_location_pin)
      expect(combined.return_type.to_s).to eq('self')
    end
  end

  context 'with return types that should probably be self' do
    let(:closure) do
      Solargraph::Pin::Namespace.new(
        name: 'Foo',
        closure: Solargraph::Pin::ROOT_PIN,
        type: :class
      )
    end

    let(:likely_selfy_pin) do
      Solargraph::Pin::Method.new(name: 'foo', closure: closure, parameters: [], comments: '@return [::Foo]')
    end

    let(:selfy_pin) { Solargraph::Pin::Method.new(name: 'foo', closure: closure, parameters: [], comments: '@return [self]') }

    it 'combines a selfy return type with a likely-selfy one' do
      combined = likely_selfy_pin.combine_with(selfy_pin)
      expect(combined.return_type.to_s).to eq('self')
    end

    it 'combines a likely-selfy return type with a selfy one' do
      combined = selfy_pin.combine_with(likely_selfy_pin)
      expect(combined.return_type.to_s).to eq('self')
    end
  end
end
