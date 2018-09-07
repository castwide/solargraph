describe Solargraph::Source::Chain::ClassVariable do
  it "resolves class variable pins" do
    foo_pin = Solargraph::Pin::ClassVariable.new(nil, '', '@@foo', '', nil, nil, nil)
    bar_pin = Solargraph::Pin::ClassVariable.new(nil, '', '@@bar', '', nil, nil, nil)
    api_map = double(Solargraph::ApiMap, :get_class_variable_pins => [foo_pin, bar_pin])
    link = Solargraph::Source::Chain::ClassVariable.new('@@bar')
    pins = link.resolve(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@@bar')
  end
end
