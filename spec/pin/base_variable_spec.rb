describe Solargraph::Pin::BaseVariable do
  it "checks assignments for equality" do
    smap = Solargraph::SourceMap.load_string('foo = "foo"')
    pin1 = smap.locals.first
    smap = Solargraph::SourceMap.load_string('foo = "foo"')
    pin2 = smap.locals.first
    expect(pin1).to eq(pin2)
    smap = Solargraph::SourceMap.load_string('foo = "bar"')
    pin2 = smap.locals.first
    expect(pin1).not_to eq(pin2)
  end

  it 'infers types from variable assignments with unparenthesized parameters' do
    source = Solargraph::Source.load_string(%(
      class Container
        def initialize; end
      end
      cnt = Container.new param1, param2
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.first
    type = pin.probe(api_map)
    expect(type.tag).to eq('Container')
  end

  it 'infers from nil nodes without locations' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
          @bar =
            if baz
              1
            end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_instance_variable_pins('Foo').first
    type = pin.probe(api_map)
    expect(type.simple_tags).to eq('Integer, nil')
  end
end
