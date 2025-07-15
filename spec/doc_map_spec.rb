# frozen_string_literal: true

describe Solargraph::DocMap do
  subject(:doc_map) do
    dm = Solargraph::DocMap.new(requires, workspace)
    dm.cache_doc_map_gems!($stderr)
    dm
  end

  let(:workspace) do
    Solargraph::Workspace.new(Dir.pwd)
  end

  let(:plain_doc_map) { Solargraph::DocMap.new([], workspace) }

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

    xit 'tracks uncached_gemspecs' do
      gemspec = Gem::Specification.new do |spec|
        spec.name = 'not_a_gem'
        spec.version = '1.0.0'
      end
      allow(Gem::Specification).to receive(:find_by_path).and_return(gemspec)
      doc_map = Solargraph::DocMap.new(['not_a_gem'], workspace)
      expect(doc_map.uncached_gemspecs).to eq([gemspec])
    end
  end

  context 'with require as bundle/require' do
    it 'imports all gems when bundler/require used' do
      doc_map_with_bundler_require = Solargraph::DocMap.new(['bundler/require'], workspace)
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
