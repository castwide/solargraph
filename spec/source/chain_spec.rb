describe Solargraph::Source::Chain do
  let(:api_map) { Solargraph::ApiMap.new }

  it "infers methods returning self from CoreFills" do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      x = []
      x.select
    ))
    api_map.virtualize source
    fragment = source.fragment_at(3, 9)
    pin = fragment.define(api_map).first
    expect(pin.return_complex_type.tag).to eq('Array<String>')
  end

  it "infers methods returning subtypes from CoreFills" do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      x = []
      x.first
    ))
    api_map.virtualize source
    fragment = source.fragment_at(3, 9)
    pin = fragment.define(api_map).first
    expect(pin.return_complex_type.tag).to eq('String')
  end

  it "detects unqualified constant names" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar
          class Inside
          end
        end
      end
      class Foo
        Bar::Inside
        class Bar
          Inside
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(8, 19)
    pin = fragment.define(api_map).first
    expect(pin.path).to eq('Foo::Bar::Inside')
    fragment = source.fragment_at(10, 11)
    pin = fragment.define(api_map).first
    expect(pin.path).to eq('Foo::Bar::Inside')
  end
end
