# frozen_string_literal: true

describe Solargraph::Parser::ParserGem::NodeProcessors::SendNode do
  # @param namespace [String]
  # @param code [String]
  # @return [Array<Solargraph::Pin::Method>]
  def method_pins_for namespace, code
    Solargraph::SourceMap.load_string(code).pins.select do |pin|
      pin.is_a?(Solargraph::Pin::Method) && pin.namespace == namespace
    end
  end

  # @return [Array<Array(String, Symbol)>]
  def accessors pins
    pins.map { |pin| [pin.name, pin.context.scope] }.sort
  end

  it 'generates accessors for class_attribute' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar
      end
    )
    expect(accessors(pins)).to eq([
                                    ['bar', :class],
                                    ['bar', :instance],
                                    ['bar=', :class],
                                    ['bar=', :instance],
                                    ['bar?', :class],
                                    ['bar?', :instance]
                                  ])
  end

  it 'generates accessors for multiple attributes' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar, :baz
      end
    )
    expect(pins.count { |pin| pin.name.start_with?('bar') }).to eq(6)
    expect(pins.count { |pin| pin.name.start_with?('baz') }).to eq(6)
  end

  it 'omits instance accessors when instance_accessor is false' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar, instance_accessor: false
      end
    )
    expect(accessors(pins)).to eq([
                                    ['bar', :class],
                                    ['bar=', :class],
                                    ['bar?', :class]
                                  ])
  end

  it 'omits instance writers when instance_writer is false' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar, instance_writer: false
      end
    )
    expect(accessors(pins)).to eq([
                                    ['bar', :class],
                                    ['bar', :instance],
                                    ['bar=', :class],
                                    ['bar?', :class],
                                    ['bar?', :instance]
                                  ])
  end

  it 'omits predicates when instance_predicate is false' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar, instance_predicate: false
      end
    )
    expect(accessors(pins)).to eq([
                                    ['bar', :class],
                                    ['bar', :instance],
                                    ['bar=', :class],
                                    ['bar=', :instance]
                                  ])
  end

  it 'marks generated accessors as attributes' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar
      end
    )
    expect(pins.all?(&:attribute?)).to be(true)
  end

  it 'gives class attribute writers a single parameter' do
    pins = method_pins_for 'Foo', %(
      class Foo
        class_attribute :bar
      end
    )
    writers = pins.select { |pin| pin.name == 'bar=' }
    expect(writers.size).to eq(2)
    expect(writers.all? { |pin| pin.parameters.map(&:name) == ['value'] }).to be(true)
  end

  it 'maps a prepend with an explicit receiver' do
    map = Solargraph::SourceMap.load_string %(
      module Mixin
        def helper; end

        String.prepend(self)
      end
    )
    refs = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Prepend) }
    expect(refs.map { |ref| [ref.namespace, ref.name] }).to include(%w[String Mixin])
  end

  it 'maps an include with an explicit receiver' do
    map = Solargraph::SourceMap.load_string %(
      module Mixin
      end

      Integer.include Mixin
    )
    refs = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Include) }
    expect(refs.map { |ref| [ref.namespace, ref.name] }).to include(%w[Integer Mixin])
  end

  it 'exposes methods from a module prepended onto another class' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      module Mixin
        def helper; end

        String.prepend(self)
      end
    ), 'test.rb')
    api_map.map source
    methods = api_map.get_methods('String', scope: :instance)
    expect(methods.map(&:name)).to include('helper')
  end
end
