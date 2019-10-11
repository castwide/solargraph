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
end
