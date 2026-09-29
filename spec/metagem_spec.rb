# frozen_string_literal: true

describe Solargraph::Metagem do
  let(:attributes) do
    {
      name: 'foo',
      full_path: '/gems/foo-1.0.0',
      spec_file: '/gems/foo-1.0.0/foo.gemspec',
      source: 'rubygems repository https://rubygems.org/',
      version: '1.0.0',
      require_paths: ['lib'],
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
end
