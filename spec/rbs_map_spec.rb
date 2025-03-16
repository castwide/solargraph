describe Solargraph::RbsMap do
  it 'loads from a gemspec' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec)
    pin = rbs_map.path_pin('RBS::EnvironmentLoader.new')
    expect(pin).to be
  end

  it 'converts constants and aliases to correct types' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec)
    pin = rbs_map.path_pin('RBS::EnvironmentLoader::DEFAULT_CORE_ROOT')
    expect(pin.return_type.tag).to eq('Pathname')
    pin = rbs_map.path_pin('RBS::EnvironmentWalker::InstanceNode')
    expect(pin.return_type.tag).to eq('Class<RBS::EnvironmentWalker::InstanceNode>')
  end
end
