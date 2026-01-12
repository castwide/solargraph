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

  it 'processes RBS class variables' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec, nil, nil)
    store = Solargraph::ApiMap::Store.new(rbs_map.pins)
    class_variable_pins = store.pins_by_class(Solargraph::Pin::ClassVariable)
    count_pins = class_variable_pins.select do |pin|
      pin.name.to_s == '@@count' && pin.context.to_s == 'Class<RBS::Types::Variable>'
    end
    expect(count_pins.length).to eq(1)
    count_pin = count_pins.first
    expect(count_pin.return_type.to_s).to eq('Integer')
  end

  it 'processes RBS class instance variables' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec, nil, nil)
    store = Solargraph::ApiMap::Store.new(rbs_map.pins)
    instance_variable_pins = store.pins_by_class(Solargraph::Pin::InstanceVariable)
    root_pins = instance_variable_pins.select do |pin|
      pin.name.to_s == '@root' && pin.context.to_s == 'Class<RBS::Namespace>' && pin.scope == :class
    end
    expect(root_pins.length).to eq(1)
    root_pin = root_pins.first
    expect(root_pin.return_type.to_s).to eq('RBS::Namespace, nil')
  end
end
