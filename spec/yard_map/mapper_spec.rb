describe Solargraph::YardMap::Mapper do
  before :all do # rubocop:disable RSpec/BeforeAfterAll
    @api_map = Solargraph::ApiMap.load('.')
  end

  def pins_with require
    doc_map = Solargraph::DocMap.new([require], [], @api_map.workspace, out: nil)
    doc_map.cache_doc_map_gems!(nil)
    doc_map.pins
  end

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
    pin = pins_with('rspec/expectations').find { |pin| pin.path == 'RSpec::Matchers#be_truthy' }
    expect(pin).not_to be_nil
    expect(pin.explicit?).to be(true)
  end

  it 'marks correct return type from Logger.new' do
    # Using logger because it's a known dependency
    pins = pins_with('logger').select { |pin| pin.path == 'Logger.new' }
    expect(pins.map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
  end

  it 'marks correct return type from RuboCop::Options.new' do
    # Using rubocop because it's a known dependency
    pins = pins_with('rubocop').select { |pin| pin.path == 'RuboCop::Options.new' }
    expect(pins.map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
    expect(pins.flat_map(&:signatures).map(&:return_type).uniq.map(&:to_s)).to eq(['self'])
  end

  it 'marks non-explicit methods' do
    # Using rspec-expectations because it's a known dependency
    pin = pins_with('rspec/expectations').find { |pin| pin.path == 'RSpec::Matchers#expect' }
    expect(pin.explicit?).to be(false)
  end

  it 'adds superclass references' do
    # Asssuming the yard gem exists because it's a known dependency
    pin = pins_with('yard').find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Superclass) && pin.name == 'YARD::CodeObjects::NamespaceObject'
    end
    expect(pin.closure.path).to eq('YARD::CodeObjects::ClassObject')
  end

  it 'adds include references' do
    # Asssuming the ast gem exists because it's a known dependency
    inc = pins_with('ast').find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Include) && pin.name == 'AST::Processor::Mixin' && pin.closure.path == 'AST::Processor'
    end
    expect(inc).to be_a(Solargraph::Pin::Reference::Include)
  end

  it 'adds extend references' do
    # Asssuming the yard gem exists because it's a known dependency
    ext = pins_with('yard').find do |pin|
      pin.is_a?(Solargraph::Pin::Reference::Extend) && pin.name == 'Enumerable' && pin.closure.path == 'YARD::Registry'
    end
    expect(ext).to be_a(Solargraph::Pin::Reference::Extend)
  end
end
