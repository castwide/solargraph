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

  it 'creates only a single, populated pin for Socket.new methods, with useful types, not polluted by inner classes without explicit initializers' do
    map = Solargraph::RbsMap::StdlibMap.load('socket')
    existing_pins = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.name == 'initialize' && pin.closure.name.to_s == 'Socket' }

    store = Solargraph::ApiMap::Store.new(map.pins)
    socket_pins = store.get_path_pins("Socket.new")
    expect(socket_pins.map(&:class)).to eq([Solargraph::Pin::Method])
    socket_pin = socket_pins.first
    expect(socket_pin.signatures.length).to eq(1)
    signature = socket_pin.signatures.first
    # some parameter types not supported as of 2025-02
    expect(signature.parameters.map(&:return_type).map(&:to_s)).to match_array(["Symbol, Integer", "Symbol, Integer", an_instance_of(String)])
  end

  it 'creates only a single, populated pin for .new methods, even if class defined in separate .rbs file than its initializer' do
    map = Solargraph::RbsMap::StdlibMap.load('logger')
    existing_pins = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.name == 'initialize' && pin.closure.name.to_s == 'Socket' }

    store = Solargraph::ApiMap::Store.new(map.pins)
    socket_pins = store.get_path_pins("Logger.new")
    expect(socket_pins.map(&:class)).to eq([Solargraph::Pin::Method])
    socket_pin = socket_pins.first
    expect(socket_pin.signatures.length).to eq(1)
    signature = socket_pin.signatures.first
    # some parameter types not supported as of 2025-02
    expect(signature.parameters.map(&:return_type).map(&:to_s)).to match_array([an_instance_of(String), "Numeric, String", "Integer", "String", an_instance_of(String), "String", "Logger::_Formatter", "String", an_instance_of(String)])
  end

  it 'processes RBS class variables' do
    map = Solargraph::RbsMap::StdlibMap.load('rbs')
    store = Solargraph::ApiMap::Store.new(map.pins)
    class_variable_pins = store.pins_by_class(Solargraph::Pin::ClassVariable)
    count_pins = class_variable_pins.select do |pin|
      pin.name.to_s == '@@count' && pin.context.to_s == 'Class<RBS::Types::Variable>'
    end
    expect(count_pins.length).to eq(1)
    count_pin = count_pins.first
    expect(count_pin.return_type.to_s).to eq('Integer')
  end

  it 'processes RBS class instance variables' do
    map = Solargraph::RbsMap::StdlibMap.load('rbs')
    store = Solargraph::ApiMap::Store.new(map.pins)
    instance_variable_pins = store.pins_by_class(Solargraph::Pin::InstanceVariable)
    root_pins = instance_variable_pins.select do |pin|
      pin.name.to_s == '@root' && pin.context.to_s == 'Class<RBS::Namespace>' && pin.scope == :class
    end
    expect(root_pins.length).to eq(1)
    root_pin = root_pins.first
    expect(root_pin.return_type.to_s).to eq('RBS::Namespace, nil')
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
end
