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

  it 'marks non-explicit methods' do
    # Using rspec-expectations because it's a known dependency
    rspec = Gem::Specification.find_by_name('rspec-expectations')
    Solargraph::Yardoc.load!(rspec)
    pins = Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
    pin = pins.find { |pin| pin.path == 'RSpec::Matchers#expect' }
    expect(pin.explicit?).to be(false)
  end
end
