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

  # @return [Array<String>]
  def mapped_paths
    described_class.new(fixture_gem('engine_gem')).pins.map(&:path)
  end

  context 'with a convention that names gem directories' do
    let(:app_convention) do
      Class.new(Solargraph::Convention::Base) do
        def gem_directories _metagem
          ['app/models', 'app/models/concerns']
        end
      end
    end

    before { Solargraph::Convention.register app_convention }

    after { Solargraph::Convention.unregister app_convention }

    it 'maps the named directories' do
      expect(mapped_paths).to include('EngineGem::Broadcastable#broadcast')
    end

    it 'maps a file under overlapping directories once' do
      expect(mapped_paths.count('EngineGem::Broadcastable#broadcast')).to eq(1)
    end
  end

  it 'maps only require paths without such a convention' do
    expect(mapped_paths).not_to include('EngineGem::Broadcastable#broadcast')
  end
end
