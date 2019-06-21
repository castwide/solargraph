require 'tmpdir'

describe Solargraph::YardMap do
  it "finds stdlib require paths" do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    expect(yard_map.pins.map(&:path)).to include('Set#add')
  end

  it "removes requires on change" do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    expect(yard_map.change([])).to be(true)
    expect(yard_map.pins.map(&:path)).not_to include('Set#add')
  end

  it "detects unchanged require paths" do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    expect(yard_map.change(['set'])).to be(false)
  end

  it "keeps cached pins on change" do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    pin1 = yard_map.path_pin('Set#add')
    yard_map.change(['set', 'json'])
    pin2 = yard_map.path_pin('Set#add')
    expect(pin1).to be(pin2)
  end

  it "collects pins from gems" do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser'])
    expect(yard_map.pins.map(&:path)).to include('Parser')
    expect(yard_map.pins.map(&:path)).to include('Parser::AST')
  end

  it "tracks unresolved requires" do
    yard_map = Solargraph::YardMap.new(required: ['set', 'not_valid'])
    expect(yard_map.unresolved_requires).to include('not_valid')
    expect(yard_map.unresolved_requires).not_to include('set')
  end

  it "ignores duplicate requires" do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser', 'parser'])
    pins = yard_map.pins.select{|p| p.path == 'Parser::AST::Node#location'}
    expect(pins.length).to eq(1)
  end

  it "ignores multiple paths to the same gem" do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser', 'parser/ast'])
    pins = yard_map.pins.select{|p| p.path == 'Parser::AST::Node#location'}
    expect(pins.length).to eq(1)
  end

  it "adds superclass references" do
    # Asssuming the yard gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['yard'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('YARD::CodeObjects::ModuleObject')
    expect(pins.map(&:path)).to include('YARD::CodeObjects::NamespaceObject#instance_mixins')
  end

  it "adds include references" do
    # Asssuming the ast gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['ast'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('AST::Processor')
    expect(pins.map(&:path)).to include('AST::Processor::Mixin#process')
  end

  it "adds extend references" do
    # Asssuming the yard gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['yard'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('YARD::Registry', scope: :class)
    expect(pins.map(&:path)).to include('Enumerable#entries')
  end

  it "includes gem dependencies based on attribute" do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser'])
    expect(yard_map.with_dependencies?).to eq(true)
    expect(yard_map.pins.map(&:path)).to include('Parser')
    expect(yard_map.pins.map(&:path)).to include('AST')
  end

  it "excludes gem dependencies based on attribute" do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser'], with_dependencies: false)
    expect(yard_map.with_dependencies?).to eq(false)
    expect(yard_map.pins.map(&:path)).to include('Parser')
    expect(yard_map.pins.map(&:path)).not_to include('AST')
  end

  it 'finds require paths in gems' do
    # Assuming the parser gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['parser'], with_dependencies: false)
    location = yard_map.require_reference('parser')
    expect(location).to be_a(Solargraph::Location)
  end

  it 'returns nil for require paths without gems' do
    yard_map = Solargraph::YardMap.new
    location = yard_map.require_reference('not_a_gem')
    expect(location).to be_nil
  end

  it "loads all gems for bundler/require" do
    yard_map = Solargraph::YardMap.new(required: ['bundler/require'], with_dependencies: false)
    # Assuming the parser gem exists because it's a Solargraph dependency
    pin = yard_map.path_pin('Parser')
    expect(pin).to be_a(Solargraph::Pin::Base)
  end
end
