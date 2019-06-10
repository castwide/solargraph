describe Solargraph::Pin::BaseMethod do
  it 'typifies from super methods' do
    source = Solargraph::Source.load_string(%(
      class Sup
        # @return [String]
        def foobar; end
      end
      class Sub < Sup
        def foobar; end
      end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Sub#foobar').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('String')
  end
end
