describe Solargraph::RbsMap do
  it 'loads from a gemspec' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec, nil, nil)
    pin = rbs_map.path_pin('RBS::EnvironmentLoader#add_collection')
    expect(pin).not_to be_nil
  end

  it 'fails if it does not find data from gemspec' do
    spec = Gem::Specification.find_by_name('backport')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec, nil, nil)
    expect(rbs_map).not_to be_resolved
  end

  it 'fails if it does not find data from name' do
    rbs_map = Solargraph::RbsMap.new('lskdflaksdfjl')
    expect(rbs_map.pins).to be_empty
  end

  it 'converts constants and aliases to correct types' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec, nil, nil)
    pin = rbs_map.path_pin('RBS::EnvironmentLoader::DEFAULT_CORE_ROOT')
    expect(pin.return_type.tag).to eq('Pathname')
    pin = rbs_map.path_pin('RBS::EnvironmentWalker::InstanceNode')
    expect(pin.return_type.tag).to eq('Class<RBS::EnvironmentWalker::InstanceNode>')
  end
end
