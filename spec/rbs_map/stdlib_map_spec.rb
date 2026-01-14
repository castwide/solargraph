describe Solargraph::RbsMap::StdlibMap do
  it "finds stdlib require paths" do
    rbs_map = Solargraph::RbsMap::StdlibMap.load('fileutils')
    pin = rbs_map.path_pin('FileUtils#chdir')
    expect(pin).not_to be_nil
  end

  it 'maps YAML' do
    rbs_map = Solargraph::RbsMap::StdlibMap.load('yaml')
    pin = rbs_map.path_pin('YAML')
    expect(pin).to be_a(Solargraph::Pin::Base)
  end

  it 'processes RBS module aliases' do
    map = Solargraph::RbsMap::StdlibMap.load('yaml')
    store = Solargraph::ApiMap::Store.new(map.pins)
    constant_pins = store.get_constants('')
    yaml_pins = constant_pins.select do |pin|
      pin.name.to_s == 'YAML'
    end
    # depending on Ruby version, this might point to Psych or the YAML module
    yaml_pins.map(&:return_type).map(&:to_s).each do |return_type|
      expect(['Module<YAML>', 'Module<Psych>']).to include(return_type)
    end
  end

  it 'pins are marked as coming from RBS parsing' do
    map = Solargraph::RbsMap::StdlibMap.load('yaml')
    store = Solargraph::ApiMap::Store.new(map.pins)
    constant_pins = store.get_constants('')
    pin = constant_pins.first
    expect(pin.source).to eq(:rbs)
  end
end
