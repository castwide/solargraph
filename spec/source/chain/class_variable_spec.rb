# frozen_string_literal: true

describe Solargraph::Source::Chain::ClassVariable do
  it 'resolves class variable pins' do
    foo_pin = Solargraph::Pin::ClassVariable.new(name: '@@foo')
    bar_pin = Solargraph::Pin::ClassVariable.new(name: '@@bar')
    api_map = instance_double(Solargraph::ApiMap, get_class_variable_pins: [foo_pin, bar_pin])
    link = described_class.new('@@bar')
    pins = link.resolve(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@@bar')
  end

  it 'resolves class variables read in a namespace body' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @@bar = 'bar'
        @@bar
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 10))
    closure = api_map.source_map('test.rb').locate_closure_pin(3, 10)
    type = chain.infer(api_map, closure, [])
    expect(type.to_s).to eq('String')
  end
end
