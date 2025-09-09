# frozen_string_literal: true

require 'bundler'
require 'benchmark'

describe Solargraph::DocMap do
  subject(:doc_map) do
    described_class.new(requires, [], workspace)
  end

  let(:out) { StringIO.new }
  let(:pre_cache) { true }
  let(:requires) { [] }

  let(:workspace) do
    Solargraph::Workspace.new(Dir.pwd)
  end

  let(:plain_doc_map) { described_class.new([], [], workspace) }

  before do
    doc_map.cache_all!(nil) if pre_cache
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
      # These are auto-required by solargraph-rspec in case the bundle
      # includes these gems.  In our case, it doesn't!
      unprovided_solargraph_rspec_requires = [
        'rspec-rails',
        'actionmailer',
        'activerecord',
        'shoulda-matchers',
        'rspec-sidekiq',
        'airborne',
        'activesupport'
      ]
      expect(doc_map.unresolved_requires - unprovided_solargraph_rspec_requires)
        .to eq(['not_a_gem'])
    end
  end

  it 'does not warn for redundant requires' do
    # Requiring 'set' is unnecessary because it's already included in core. It
    # might make sense to log redundant requires, but a warning is overkill.
    allow(Solargraph.logger).to receive(:warn).and_call_original
    Solargraph::DocMap.new(['set'], [])
    expect(Solargraph.logger).not_to have_received(:warn).with(/path set/)
  end

  context 'when deserialization takes a while' do
    let(:pre_cache) { false }
    let(:requires) { ['backport'] }

    before do
      # proxy this method to simulate a long-running deserialization
      allow(Benchmark).to receive(:measure) do |&block|
        block.call
        5.0
      end
    end

    it 'logs timing' do
      pending('logging being implemented')
      # force lazy evaluation
      _pins = doc_map.pins
      expect(out.string).to include('Deserialized ').and include(' gem pins ').and include(' ms')
    end
  end

  it 'does not warn for redundant requires' do
    # Requiring 'set' is unnecessary because it's already included in core. It
    # might make sense to log redundant requires, but a warning is overkill.
    allow(Solargraph.logger).to receive(:warn)
    Solargraph::DocMap.new(['set'], [], workspace)
    expect(Solargraph.logger).not_to have_received(:warn).with(/path set/)
  end

  it 'ignores nil requires' do
    expect { Solargraph::DocMap.new([nil], [], workspace) }.not_to raise_error
  end

  it 'ignores empty requires' do
    expect { Solargraph::DocMap.new([''], [], workspace) }.not_to raise_error
  end

  it 'collects dependencies' do
    doc_map = Solargraph::DocMap.new(['rspec'], [], workspace)
    expect(doc_map.dependencies.map(&:name)).to include('rspec-core')
  end

  context 'with require as bundle/require' do
    it 'imports all gems when bundler/require used' do
      doc_map_with_bundler_require = described_class.new(['bundler/require'], [], workspace)
      doc_map_with_bundler_require.cache_all!(nil)
      expect(doc_map_with_bundler_require.pins.length - plain_doc_map.pins.length).to be_positive
    end
  end

  context 'with a require not needed by Ruby core' do
    let(:requires) { ['set'] }

    it 'does not warn' do
      # Requiring 'set' is unnecessary because it's already included in core. It
      # might make sense to log redundant requires, but a warning is overkill.
      allow(Solargraph.logger).to receive(:warn)
      doc_map
      expect(Solargraph.logger).not_to have_received(:warn).with(/path set/)
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

    it 'collects dependencies' do
      expect(doc_map.dependencies.map(&:name)).to include('rspec-core')
    end
  end

  context 'with convention' do
    let(:pre_cache) { false }

    it 'includes convention requires from environ' do
      dummy_convention = Class.new(Solargraph::Convention::Base) do
        def global(doc_map)
          Solargraph::Environ.new(
            requires: ['convention_gem1', 'convention_gem2']
          )
        end
      end

      Solargraph::Convention.register dummy_convention

      doc_map = Solargraph::DocMap.new(['original_gem'], [], workspace)

      expect(doc_map.requires).to include('original_gem', 'convention_gem1', 'convention_gem2')
    ensure
      # Clean up the registered convention
      Solargraph::Convention.unregister dummy_convention
    end
  end
end
