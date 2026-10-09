# frozen_string_literal: true

describe Solargraph::Collection::Gem do
  let(:full_path) { File.absolute_path(File.join('spec', 'fixtures', 'engine_gem')) }

  let(:metagem) do
    Solargraph::Metagem.new(name: 'engine_gem', full_path: full_path,
                            spec_file: File.join(full_path, 'engine_gem.gemspec'),
                            source: "source at #{full_path}", version: '1.0.0',
                            require_paths: ['lib'], dependencies: [])
  end

  it 'maps code an engine autoloads from app/' do
    # Engines such as turbo-rails define concerns under app/, outside their require paths.
    paths = described_class.new(metagem).pins.map(&:path)
    expect(paths).to include('EngineGem::Broadcastable#broadcast')
  end
end
