describe Solargraph::RbsMap::StdlibMap do
  it "finds stdlib require paths" do
    rbs_map = Solargraph::RbsMap::StdlibMap.load('set')
    pin = rbs_map.path_pin('Set#add')
    expect(pin).to be
  end

  it 'adds overrides' do
    # @todo Unlike the YardMap stdlib, the RBS version reports the correct
    #   return type for Pathname#Join. Delete or modify this test depending
    #   on how StdLibFills will be handled going forward.
    rbs_map = Solargraph::RbsMap::StdlibMap.load('pathname')
    pin = rbs_map.path_pin('Pathname#join')
    expect(pin.return_type.tag).to eq('Pathname')
  end
end
