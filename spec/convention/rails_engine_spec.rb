# frozen_string_literal: true

describe Solargraph::Convention::RailsEngine do
  # @param name [String]
  # @return [Solargraph::Metagem]
  def fixture_gem name
    full_path = File.absolute_path(File.join('spec', 'fixtures', name))
    Solargraph::Metagem.new(name: name, full_path: full_path,
                            spec_file: File.join(full_path, "#{name}.gemspec"),
                            source: "source at #{full_path}", version: '1.0.0',
                            require_paths: ['lib'], dependencies: [])
  end

  it "returns an engine's default autoload roots, without assets or javascript" do
    expect(described_class.new.gem_directories(fixture_gem('engine_gem')))
      .to eq(['app/models', 'app/models/concerns', 'test/mailers/previews'])
  end

  it 'returns nothing for a gem with app/ that is not an engine' do
    expect(described_class.new.gem_directories(fixture_gem('app_gem'))).to eq([])
  end

  it 'is registered with Convention' do
    expect(Solargraph::Convention.gem_directories(fixture_gem('engine_gem'))).to include('app/models/concerns')
  end
end
