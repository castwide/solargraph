require 'fileutils'
require 'set'
require 'tmpdir'

describe Solargraph::YardMap do
  it 'removes requires on change' do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    expect(yard_map.change([], '', [])).to be(true)
    expect(yard_map.pins.map(&:path)).not_to include('Set#add')
  end

  it 'detects unchanged require paths' do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    expect(yard_map.change(['set'].to_set, '', [].to_set)).to be(false)
  end

  it 'keeps cached pins on change' do
    yard_map = Solargraph::YardMap.new(required: ['set'])
    pin1 = yard_map.path_pin('Set#add')
    yard_map.change(%w[set json], '', [])
    pin2 = yard_map.path_pin('Set#add')
    expect(pin1).to be(pin2)
  end

  it 'collects pins from gems' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['rspec'])
    rspec = yard_map.path_pin('RSpec')
    expect(rspec).to be
  end

  it 'tracks unresolved requires' do
    yard_map = Solargraph::YardMap.new(required: ['not_valid'])
    expect(yard_map.unresolved_requires).to include('not_valid')
  end

  it 'tracks missing documentation' do
    # @todo Improve this test. Figure a way to mock an installed gem
    #   without a yardoc.
    yard_map = Solargraph::YardMap.new(required: %w[set not_valid])
    expect(yard_map.missing_docs).not_to include('not_valid')
    expect(yard_map.missing_docs).not_to include('set')
  end

  it 'ignores duplicate requires' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: %w[rspec rspec])
    pins = yard_map.pins.select { |p| p.path == 'RSpec::Core' }
    expect(pins.length).to eq(1)
  end

  it 'ignores multiple paths to the same gem' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['rspec', 'rspec/core'])
    pins = yard_map.pins.select { |p| p.path == 'RSpec::Core.path_to_executable' }
    expect(pins.length).to eq(1)
  end

  it 'adds superclass references' do
    # Asssuming the yard gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['yard'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('YARD::CodeObjects::ModuleObject')
    expect(pins.map(&:path)).to include('YARD::CodeObjects::NamespaceObject#instance_mixins')
  end

  it 'adds include references' do
    # Asssuming the ast gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['ast'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('AST::Processor')
    expect(pins.map(&:path)).to include('AST::Processor::Mixin#process')
  end

  it 'adds extend references' do
    # Asssuming the yard gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['yard'])
    api_map = Solargraph::ApiMap.new
    api_map.index yard_map.pins
    pins = api_map.get_methods('YARD::Registry', scope: :class)
    expect(pins.map(&:path)).to include('Enumerable#entries')
  end

  it 'includes gem dependencies based on attribute' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['rspec'])
    expect(yard_map.with_dependencies?).to eq(true)
    rspec = yard_map.path_pin('RSpec')
    expect(rspec).to be
    ast = yard_map.path_pin('RSpec::Core')
    expect(ast).to be
  end

  it 'excludes gem dependencies based on attribute' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['rspec'], with_dependencies: false)
    expect(yard_map.with_dependencies?).to eq(false)
    rspec = yard_map.path_pin('RSpec')
    expect(rspec).to be
    core = yard_map.path_pin('RSpec::Core')
    expect(core).to be_nil
  end

  it 'finds require paths in gems' do
    # Assuming the rspec gem exists because it's a Solargraph dependency
    yard_map = Solargraph::YardMap.new(required: ['rspec'], with_dependencies: false)
    location = yard_map.require_reference('rspec')
    expect(location).to be_a(Solargraph::Location)
  end

  it 'returns nil for require paths without gems' do
    yard_map = Solargraph::YardMap.new
    location = yard_map.require_reference('not_a_gem')
    expect(location).to be_nil
  end

  it 'changes the directory' do
    yard_map = Solargraph::YardMap.new
    yard_map.change [], '/my/directory', []
    expect(yard_map.directory).to eq('/my/directory')
  end

  it 'adds automatically imported gems to YardMap' do
    Dir.mktmpdir do |tmp|
      FileUtils.cp_r 'spec/fixtures/workspace-with-gemfile', tmp
      yard_map = Solargraph::YardMap.new
      yard_map.change(['bundler/require'].to_set, "#{tmp}/workspace-with-gemfile", Set.new)
      pin = yard_map.path_pin('Backport')
      expect(pin).to be
    end
  end

  it 'ignores workspace requires starting with `/`' do
    yard_map = Solargraph::YardMap.new
    yard_map.change(['/'].to_set, '', [].to_set)
  end

  it 'ignores require references starting with `/`' do
    yard_map = Solargraph::YardMap.new
    yard_map.require_reference('/')
  end
end
