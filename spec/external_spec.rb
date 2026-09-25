# frozen_string_literal: true

describe Solargraph::External do
  let(:directory) { File.join('spec', 'fixtures', 'external_bundled_gem') }
  let(:requires) { ['backport', 'gem/with/yard/macros', 'reverse_markdown'] }
  let(:external) { described_class.new(directory, requires) }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.rm_f File.join('spec', 'fixtures', 'external_bundled_gem', 'Gemfile.lock')
    Solargraph.with_clean_env do
      `cd #{File.join('spec', 'fixtures', 'external_bundled_gem')} && bundle install`
    end
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.rm_f File.join('spec', 'fixtures', 'external_bundled_gem', 'Gemfile.lock')
  end

  context 'with uncached sources' do
    let(:metagem) { Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport')) }

    it 'tracks and updates unloaded gems' do
      Solargraph::Collection::Gem.uncache(metagem)
      expect(external.unloaded_gems.map(&:name)).to include('backport')
      Solargraph::Collection::Gem.load(metagem)
      expect(external.update(requires)).to be(true)
      expect(external.unloaded_gems.map(&:name)).not_to include('backport')
      expect(external.loaded_gems.map(&:name)).to include('backport')
    end
  end

  context 'with cached sources' do
    before(:all) do # rubocop:disable RSpec/BeforeAfterAll
      %w[backport reverse_markdown nokogiri].each do |name|
        metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name(name))
        Solargraph::Collection::Gem.load(metagem) unless Solargraph::Collection::Gem.cached?(metagem)
      end
    end

    it 'loads bundled gems' do
      gem_names = external.loaded_gems.map(&:name)
      expect(gem_names).to include('backport')
      expect(gem_names).to include('gem-with-yard-macros')
      expect(gem_names).to include('reverse_markdown')
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

    it 'loads gems from transitive dependencies' do
      # nokogiri is a transitive dependency of reverse_markdown
      expect(external.loaded_gems.map(&:name)).to include('nokogiri')
    end
  end

  context 'with RBS collection' do
    let(:directory) { File.join('spec', 'fixtures', 'rbs_collection') }
    let(:requires) { [] }

    it 'combines gem_rbs_collection pins' do
      pin = external.pins.find { |pin| pin.path == 'Addressable::URI.parse' }
      expect(pin).to be_a(Solargraph::Pin::Method)
    end

    it 'combines local source pins' do
      pin = external.pins.find { |pin| pin.path == 'Foo#bar' }
      expect(pin.return_type.to_s).to eq('String')
    end

    it 'appends local source pins' do
      pin = external.pins.find { |pin| pin.path == 'Foo#baz' }
      expect(pin.return_type.to_s).to eq('Integer')
    end
  end

  it 'tracks unresolved requires' do
    external = described_class.new(directory, ['not_a_valid_path'])
    expect(external.unresolved_requires).to eq(['not_a_valid_path'])
  end

  it 'imports all gems when bundler/require is required' do
    external = described_class.new(directory, ['bundler/require'])
    gem_names = external.loaded_gems.map(&:name)
    expect(gem_names).to include('backport')
    expect(gem_names).to include('gem-with-yard-macros')
    expect(gem_names).to include('reverse_markdown')
  end

  it 'ignores duplicate gems' do
    external = described_class.new(directory, ['backport', 'backport/version'])
    backport_pins = external.pins.select { |pin| pin.path == 'Backport' }
    expect(backport_pins).to be_one
  end
end
