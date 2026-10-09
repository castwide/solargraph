# frozen_string_literal: true

describe Solargraph::Collection::Gem do
  # @param name [String]
  # @return [Solargraph::Metagem]
  def fixture_gem name
    full_path = File.absolute_path(File.join('spec', 'fixtures', name))
    Solargraph::Metagem.new(name: name, full_path: full_path,
                            spec_file: File.join(full_path, "#{name}.gemspec"),
                            source: "source at #{full_path}", version: '1.0.0',
                            require_paths: ['lib'], dependencies: [])
  end

  it 'maps code an engine autoloads from app/' do
    paths = described_class.new(fixture_gem('engine_gem')).pins.map(&:path)
    expect(paths).to include('EngineGem::Broadcastable#broadcast')
  end

  it 'maps each autoloaded file once' do
    paths = described_class.new(fixture_gem('engine_gem')).pins.map(&:path)
    expect(paths.count('EngineGem::Broadcastable#broadcast')).to eq(1)
  end

  it 'skips app/ in a gem that is not an engine' do
    paths = described_class.new(fixture_gem('app_gem')).pins.map(&:path)
    expect(paths).not_to include('AppGem::Thing')
  end
end
