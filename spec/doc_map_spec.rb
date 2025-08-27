# frozen_string_literal: true

describe Solargraph::DocMap do
  before :all do
    # We use ast here because it's a known dependency.
    gemspec = Gem::Specification.find_by_name('ast')
    yard_pins = Solargraph::GemPins.build_yard_pins([], gemspec)
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
    expect(doc_map.unresolved_requires).to include('not_a_gem')
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
    allow(Solargraph.logger).to receive(:warn).and_call_original
    Solargraph::DocMap.new(['set'], [])
    expect(Solargraph.logger).not_to have_received(:warn).with(/path set/)
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

  it 'includes convention requires from environ' do
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def global(doc_map)
        Solargraph::Environ.new(
          requires: ['convention_gem1', 'convention_gem2']
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    doc_map = Solargraph::DocMap.new(['original_gem'], [])

    expect(doc_map.requires).to include('original_gem', 'convention_gem1', 'convention_gem2')

    # Clean up the registered convention
    Solargraph::Convention.deregister dummy_convention
  end
end
