# frozen_string_literal: true

require 'bundler'

describe Solargraph::DocMap do
  subject(:doc_map) do
    Solargraph::DocMap.new(requires, workspace)
  end

  let(:pre_cache) { true }
  let(:requires) { [] }

  let(:workspace) do
    Solargraph::Workspace.new(Dir.pwd)
  end

  let(:plain_doc_map) { Solargraph::DocMap.new([], workspace) }

  before do
    doc_map.cache_doc_map_gems!($stderr) if pre_cache
  end

  context 'with a require in solargraph test bundle' do
    let(:requires) do
      ['ast']
    end

    it 'generates pins from gems' do
      node_pin = doc_map.pins.find { |pin| pin.path == 'AST::Node' }
      expect(node_pin).to be_a(Solargraph::Pin::Namespace)
    end
  end

  context 'with an invalid require' do
    let(:requires) do
      ['not_a_gem']
    end

    it 'tracks unresolved requires' do
      expect(doc_map.unresolved_requires).to eq(['not_a_gem'])
    end
  end

  context 'with an uncached but valid gemspec' do
    let(:uncached_gemspec) do
      Gem::Specification.new('uncached_gem', '1.0.0')
    end
    let(:requires) { ['uncached_gem'] }
    let(:pre_cache) { false }
    let(:workspace) { instance_double(Solargraph::Workspace) }

    before do
      pincache = instance_double(Solargraph::PinCache)
      allow(workspace).to receive(:resolve_require).with('uncached_gem').and_return([uncached_gemspec])
      allow(workspace).to receive(:fetch_dependencies).with(uncached_gemspec).and_return([])
      allow(workspace).to receive(:fresh_pincache).and_return(pincache)
      allow(pincache).to receive(:deserialize_combined_pin_cache).with(uncached_gemspec).and_return(nil)
    end

    it 'tracks uncached_gemspecs' do
      expect(doc_map.uncached_gemspecs).to eq([uncached_gemspec])
    end
  end

  context 'with require as bundle/require' do
    it 'imports all gems when bundler/require used' do
      doc_map_with_bundler_require = Solargraph::DocMap.new(['bundler/require'], workspace)
      doc_map_with_bundler_require.cache_doc_map_gems!($stderr)
      expect(doc_map_with_bundler_require.pins.length - plain_doc_map.pins.length).to be_positive
    end
  end

  context 'with a require not needed by Ruby core' do
    let(:requires) { ['set'] }

    it 'does not warn' do
      # Requiring 'set' is unnecessary because it's already included in core. It
      # might make sense to log redundant requires, but a warning is overkill.
      expect(Solargraph.logger).not_to receive(:warn).with(/path set/)
      doc_map
    end
  end

  context 'with a nil require' do
    let(:requires) { [nil] }

    it 'does not raise error' do
      expect { doc_map }.not_to raise_error
    end
  end

  context 'with an empty require' do
    let(:requires) { [''] }

    it 'does not raise error' do
      expect { doc_map }.not_to raise_error
    end
  end

  context 'with a require that has dependencies' do
    let(:requires) { ['rspec'] }
    let(:example_dependency) { 'rspec-core' }

    it 'collects dependencies' do
      expect(doc_map.dependencies.map(&:name)).to include(example_dependency)
    end
  end
end
