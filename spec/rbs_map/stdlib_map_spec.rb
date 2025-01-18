describe Solargraph::RbsMap::StdlibMap do
  it "finds stdlib require paths" do
    rbs_map = Solargraph::RbsMap::StdlibMap.load('fileutils')
    pin = rbs_map.path_pin('FileUtils#chdir')
    expect(pin).to be
  end

  it 'adds overrides' do
    # @todo Unlike the YardMap stdlib, the RBS version reports the correct
    #   return type for Pathname#Join. Delete or modify this test depending
    #   on how StdLibFills will be handled going forward.
    rbs_map = Solargraph::RbsMap::StdlibMap.load('pathname')
    pin = rbs_map.path_pin('Pathname#join')
    expect(pin.signatures.first.return_type.tag).to eq('Pathname')
  end

  it 'maps YAML' do
    rbs_map = Solargraph::RbsMap::StdlibMap.load('yaml')
    pin = rbs_map.path_pin('YAML')
    expect(pin).to be_a(Solargraph::Pin::Base)
  end
end
