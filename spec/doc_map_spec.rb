# frozen_string_literal: true

describe Solargraph::DocMap do
  before :all do
    # We use ast here because it's a known dependency.
    gemspec = Gem::Specification.find_by_name('ast')
    yard_pins = Solargraph::GemPins.build_yard_pins(gemspec)
    Solargraph::PinCache.serialize_yard_gem(gemspec, yard_pins)
  end

  it 'generates pins from gems' do
    doc_map = Solargraph::DocMap.new(['ast'], [])
    doc_map.cache_all!($stderr)
    node_pin = doc_map.pins.find { |pin| pin.path == 'AST::Node' }
    expect(node_pin).to be_a(Solargraph::Pin::Namespace)
  end

  it 'tracks unresolved requires' do
    doc_map = Solargraph::DocMap.new(['not_a_gem'], [])
    expect(doc_map.unresolved_requires).to eq(['not_a_gem'])
  end

  it 'tracks uncached_gemspecs' do
    gemspec = Gem::Specification.new do |spec|
      spec.name = 'not_a_gem'
      spec.version = '1.0.0'
    end
    allow(Gem::Specification).to receive(:find_by_path).and_return(gemspec)
    doc_map = Solargraph::DocMap.new(['not_a_gem'], [gemspec])
    expect(doc_map.uncached_yard_gemspecs).to eq([gemspec])
    expect(doc_map.uncached_rbs_collection_gemspecs).to eq([gemspec])
  end

  it 'imports all gems when bundler/require used' do
    workspace = Solargraph::Workspace.new(Dir.pwd)
    plain_doc_map = Solargraph::DocMap.new([], [], workspace)
    doc_map_with_bundler_require = Solargraph::DocMap.new(['bundler/require'], [], workspace)

    expect(doc_map_with_bundler_require.pins.length - plain_doc_map.pins.length).to be_positive
  end

  it 'does not warn for redundant requires' do
    # Requiring 'set' is unnecessary because it's already included in core. It
    # might make sense to log redundant requires, but a warning is overkill.
    expect(Solargraph.logger).not_to receive(:warn).with(/path set/)
    Solargraph::DocMap.new(['set'], [])
  end

  it 'ignores nil requires' do
    expect { Solargraph::DocMap.new([nil], []) }.not_to raise_error
  end

  it 'ignores empty requires' do
    expect { Solargraph::DocMap.new([''], []) }.not_to raise_error
  end

  it 'collects dependencies' do
    doc_map = Solargraph::DocMap.new(['rspec'], [])
    expect(doc_map.dependencies.map(&:name)).to include('rspec-core')
  end

  context 'with a plugin' do
    let(:environ_pin) do
      Solargraph::Pin::Method.new(name: 'my_method', return_type: Solargraph::ComplexType.parse('String'), source: :solargraph_foo)
    end

    before do
      allow(Solargraph::Convention)
        .to(receive(:for_global))
        .and_return(Solargraph::Environ.new(pins: [environ_pin]))
    end

    it 'includes environ pins' do
      # we know this is included in our bundle
      doc_map = Solargraph::DocMap.new([], [])

      expect(doc_map.pins).to include(new_pin)
    end

    let(:cache_pin) { Solargraph::Pin::Method.new(name: 'my_method', source: :cache) }

    let(:fake_gem_name) { 'fake_gem_name' }
    let(:fake_gemspec) { double('Gem::Specification', name: fake_gem_name) }

    it 'merges environ pins with existing pins' do
      allow(Solargraph::PinCache).to receive(:deserialize_combined_gem).and_return([cache_pin])
      allow(Gem::Specification).to receive(:find_by_path).with(fake_gem_name).and_return(fake_gemspec)
      allow(fake_gemspec).to receive(:dependencies).and_return([])
      allow(fake_gemspec).to receive(:development_dependencies).and_return([])
      allow(fake_gemspec).to receive(:version).and_return('1.0.0')
      doc_map = Solargraph::DocMap.new([fake_gem_name], [])
      expect(Solargraph::PinCache).to have_received(:deserialize_combined_gem).with(fake_gemspec, "unresolved")
      expect(Solargraph::Convention).to have_received(:for_global)
      expect(doc_map.pins.map(&:source)).to eq([:combined])
      expect(doc_map.pins.map(&:return_type).map(&:rooted_tag)).to eq(['String'])
      expect(doc_map.pins.length).to eq(1)
    end
  end
end
