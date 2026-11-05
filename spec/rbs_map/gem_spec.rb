# frozen_string_literal: true

describe Solargraph::RbsMap::Gem do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    spec = Gem::Specification.find_by_name('rbs')
    metagem = Solargraph::Metagem.from_specification(spec)
    @gem = described_class.new(metagem)
  end
  let(:gem) { @gem }

  it 'loads from a gemspec' do
    pin = gem.path_pins('RBS::EnvironmentLoader#add_collection').first
    expect(pin).not_to be_nil
  end

  it 'converts constants and aliases to correct types' do
    pin = gem.path_pins('RBS::EnvironmentLoader::DEFAULT_CORE_ROOT').first
    expect(pin.return_type.tag).to eq('Pathname')
    pin = gem.path_pins('RBS::EnvironmentWalker::InstanceNode').first
    expect(pin.return_type.tag).to eq('Class<RBS::EnvironmentWalker::InstanceNode>')
  end

  it 'processes RBS class variables' do
    store = Solargraph::ApiMap::Store.new(gem.pins)
    class_variable_pins = store.pins_by_class(Solargraph::Pin::ClassVariable)
    count_pins = class_variable_pins.select do |pin|
      pin.name.to_s == '@@count' && pin.context.to_s == 'Class<RBS::Types::Variable>'
    end
    expect(count_pins.length).to eq(1)
    count_pin = count_pins.first
    expect(count_pin.return_type.to_s).to eq('Integer')
  end

  it 'processes RBS class instance variables' do
    store = Solargraph::ApiMap::Store.new(gem.pins)
    instance_variable_pins = store.pins_by_class(Solargraph::Pin::InstanceVariable)
    root_pins = instance_variable_pins.select do |pin|
      pin.name.to_s == '@root' && pin.context.to_s == 'Class<RBS::Namespace>' && pin.scope == :class
    end
    expect(root_pins.length).to eq(1)
    root_pin = root_pins.first
    expect(root_pin.return_type.to_s).to eq('RBS::Namespace, nil')
  end

  it 'ignores signatures outside the sig directory' do
    # The rbs gem ships Ruby core signatures in core/, which must not
    # shadow the core pins Solargraph maps itself
    expect(gem.path_pins('Hash#[]')).to be_empty
  end

  it 'does not shadow core fills with the rbs gem core signatures' do
    # CoreFills overrides Class#allocate to return self; the rbs gem
    # copy in core/ returns untyped and would win the method stack
    api_map = Solargraph::ApiMap.new(pins: gem.pins)
    source = Solargraph::Source.load_string('String.allocate', 'test.rb')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 10))
    expect(chain.infer(api_map, Solargraph::Pin::ROOT_PIN, []).to_s).to eq('String')
  end
end
