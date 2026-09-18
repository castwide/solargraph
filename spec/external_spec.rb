# frozen_string_literal: true

describe Solargraph::External do
  let(:directory) { File.join('spec', 'fixtures', 'external_bundled_gem') }
  let(:requires) { ['backport', 'gem/with/yard/macros', 'reverse_markdown'] }
  let(:external) { described_class.new(directory, requires) }

  context 'with uncached sources' do
    before(:all) do
      metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport'))
      Solargraph::Collection::Gem.uncache(metagem)
    end

    it 'tracks unloaded gems' do
      expect(external.unloaded_gems.map(&:name)).to include('backport')
    end
  end

  context 'with cached sources' do
    before(:all) do
      ['backport', 'reverse_markdown', 'nokogiri'].each do |name|
        metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name(name))
        Solargraph::Collection::Gem.load(metagem) unless Solargraph::Collection::Gem.cached?(metagem)
      end
    end

    it 'loads bundled gems' do
      expect(external.loaded_gems.map(&:name)).to include('backport')
      expect(external.loaded_gems.map(&:name)).to include('gem-with-yard-macros')
      expect(external.loaded_gems.map(&:name)).to include('reverse_markdown')
    end

    it 'loads transitive dependencies' do
      expect(external.loaded_gems.map(&:name)).to include('nokogiri')
    end

    it 'loads pins from system sources' do
      paths = external.pins.map(&:path)
      expect(paths).to include('Backport')
      expect(paths).to include('Backport::Server')
      expect(paths).to include('Backport.prepare_stdio_server')
    end

    it 'loads pins from path sources' do
      pins = external.pins.select { |pin| pin.path&.start_with?('Gem::With::Yard::Macros') }
      expect(pins.length).to be_positive
    end

    it 'loads pins from transitive dependencies' do
      pins = external.pins.select { |pin| pin.path&.start_with?('Nokogiri') }
      expect(pins.length).to be_positive
    end
  end

  it 'tracks unresolved requires' do
    external = described_class.new(directory, ['not_a_valid_path'])
    expect(external.unresolved_requires).to eq(['not_a_valid_path'])
  end

  it 'imports all gems when bundler/require is required' do
    external = described_class.new(directory, ['bundler/require'])
    expect(external.loaded_gems.map(&:name)).to include('backport')
    expect(external.loaded_gems.map(&:name)).to include('gem-with-yard-macros')
    expect(external.loaded_gems.map(&:name)).to include('reverse_markdown')
  end
end
