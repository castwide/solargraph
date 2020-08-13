describe Solargraph::Convention::Stdlib do
  it 'adds overrides' do
    # Pathname is a stdlib component that doesn't have method return types in
    # the yardocs. This test makes sure that YardMap injects overrides from
    # StdlibFills.
    source = Solargraph::Source.load_string(%(
      require 'pathname'
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Pathname#join').first
    expect(pin.return_type.tag).to eq('Pathname')
  end
end
