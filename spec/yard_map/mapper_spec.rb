describe Solargraph::YardMap::Mapper do
  it 'converts nil docstrings to empty strings' do
    dir = File.absolute_path(File.join('spec', 'fixtures', 'yard_map'))
    Dir.chdir dir do
      YARD::Registry.load([File.join(dir, 'attr.rb')], true)
      mapper = Solargraph::YardMap::Mapper.new(YARD::Registry.all)
      pins = mapper.map
      pin = pins.select { |pin| pin.path == 'Foo#bar' }.first
      expect(pin.comments).to be_a(String)
    end
    # Cleanup
    FileUtils.remove_entry_secure File.join(dir, '.yardoc')
  end

  it 'marks explicit methods' do
    # Using rspec-expectations because it's a known dependency
    rspec = Gem::Specification.find_by_name('rspec-expectations')
    Solargraph::Yardoc.cache(rspec)
    Solargraph::Yardoc.load!(rspec)
    pins = Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
    pin = pins.find { |pin| pin.path == 'RSpec::Matchers#be_truthy' }
    expect(pin.explicit?).to be(true)
  end

  it 'marks correct return type from Logger.new' do
    # Using logger because it's a known dependency
    logger = Gem::Specification.find_by_name('logger')
    Solargraph::Yardoc.cache(logger)
    registry = Solargraph::Yardoc.load!(logger)
    pins = Solargraph::YardMap::Mapper.new(registry).map
    pins = pins.select { |pin| pin.path == 'Logger.new' }
    expect(pins.map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
  end

  it 'marks correct return type from RuboCop::Options.new' do
    # Using rubocop because it's a known dependency
    rubocop = Gem::Specification.find_by_name('rubocop')
    Solargraph::Yardoc.cache(rubocop)
    Solargraph::Yardoc.load!(rubocop)
    pins = Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
    pins = pins.select { |pin| pin.path == 'RuboCop::Options.new' }
    expect(pins.map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
    expect(pins.flat_map(&:signatures).map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
  end

  it 'marks non-explicit methods' do
    # Using rspec-expectations because it's a known dependency
    rspec = Gem::Specification.find_by_name('rspec-expectations')
    Solargraph::Yardoc.load!(rspec)
    pins = Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
    pin = pins.find { |pin| pin.path == 'RSpec::Matchers#expect' }
    expect(pin.explicit?).to be(false)
  end

  it 'adds superclass references' do
    # Asssuming the yard gem exists because it's a known dependency
    gemspec = Gem::Specification.find_by_name('yard')
    Solargraph::Yardoc.cache(gemspec)
    pins = Solargraph::YardMap::Mapper.new(Solargraph::Yardoc.load!(gemspec)).map
    pin = pins.find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Superclass) && pin.name == 'YARD::CodeObjects::NamespaceObject'
    end
    expect(pin.closure.path).to eq('YARD::CodeObjects::ClassObject')
  end

  it 'adds include references' do
    # Asssuming the ast gem exists because it's a known dependency
    gemspec = Gem::Specification.find_by_name('ast')
    Solargraph::Yardoc.cache(gemspec)
    pins = Solargraph::YardMap::Mapper.new(Solargraph::Yardoc.load!(gemspec)).map
    inc= pins.find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Include) && pin.name == 'AST::Processor::Mixin' && pin.closure.path == 'AST::Processor'
    end
    expect(inc).to be_a(Solargraph::Pin::Reference::Include)
  end

  it 'adds extend references' do
    # Asssuming the yard gem exists because it's a known dependency
    gemspec = Gem::Specification.find_by_name('yard')
    Solargraph::Yardoc.cache(gemspec)
    pins = Solargraph::YardMap::Mapper.new(Solargraph::Yardoc.load!(gemspec)).map
    ext = pins.find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Extend) && pin.name == 'Enumerable' && pin.closure.path == 'YARD::Registry'
    end
    expect(ext).to be_a(Solargraph::Pin::Reference::Extend)
  end
end
