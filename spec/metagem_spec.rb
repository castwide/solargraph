# frozen_string_literal: true

describe Solargraph::Metagem do
  let(:attributes) do
    {
      name: 'foo',
      full_path: '/gems/foo-1.0.0',
      spec_file: '/gems/foo-1.0.0/foo.gemspec',
      source: 'rubygems repository https://rubygems.org/',
      version: '1.0.0',
      dependencies: ['bar']
    }
  end

  let(:metagem) { described_class.new(**attributes) }

  it 'equates metagems describing the same gem' do
    expect(metagem).to eq(described_class.new(**attributes))
  end

  it 'deduplicates metagems describing the same gem' do
    # External tracks gems in a Set, so a gem reached by two routes is only
    # loaded once when equal instances collapse.
    expect(Set.new([metagem, described_class.new(**attributes)]).length).to eq(1)
  end

  it 'distinguishes different versions of the same gem' do
    other = described_class.new(**attributes, version: '2.0.0', full_path: '/gems/foo-2.0.0')
    expect(metagem).not_to eq(other)
  end

  it 'equates a string version with a Gem::Version' do
    expect(metagem).to eq(described_class.new(**attributes, version: Gem::Version.new('1.0.0')))
  end

  describe '.from_specification' do
    let(:specification) do
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0.0'
        spec.add_dependency 'runtime_dep'
        spec.add_development_dependency 'dev_dep'
      end
    end

    it 'omits development dependencies' do
      # A gem cannot expose its development dependencies through its own API,
      # so loading them costs time without resolving any type.
      expect(described_class.from_specification(specification).dependencies).to eq(['runtime_dep'])
    end
  end

  describe '#require_paths' do
    it 'defaults to lib' do
      metagem = described_class.new(**attributes)
      expect(metagem.require_paths).to eq(['lib'])
    end

    it 'uses `require_paths=` from spec file' do
      gem_path = File.join('spec', 'fixtures', 'gem-with-require-paths')
      metagem = described_class.new(**attributes.merge({
        full_path: gem_path,
        spec_file: File.join(gem_path, 'gem-with-require-paths.gemspec')
      }))
      expect(metagem.require_paths).to eq(['other'])
    end
  end
end
