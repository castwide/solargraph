describe Solargraph::ApiMap::Probe do
  it "infers types from `new` methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foo
      end
      foo = Foo.new
      foo._
    ))
    api_map.virtualize source
    type = api_map.probe.infer_signature_type('foo', source.pins.first, source.locals)
    expect(type).to eq('Foo')
  end

  it "infers nested namespace types from `new` methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foo
        class Bar
        end
      end
      bar = Foo::Bar.new
      bar._
    ))
    api_map.virtualize source
    type = api_map.probe.infer_signature_type('bar', source.pins.first, source.locals)
    expect(type).to eq('Foo::Bar')
  end

  it "returns empty arrays for unrecognized signatures" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      foobarbaz
    ))
    api_map.virtualize source
    pins = api_map.probe.infer_signature_pins('foobarbaz', source.pins.first, source.locals)
    expect(pins).to be_empty
  end

  it "infers a nested namespace type" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar
        end
      end

      module Foo
      end
    ))
    api_map.virtualize source
    mod = source.pins.select{|pin| pin.name == 'Foo'}.last
    type = api_map.probe.infer_signature_type('Bar', mod, [])
    expect(type).to eq('Class<Foo::Bar>')
  end
end
