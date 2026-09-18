# frozen_string_literal: true

describe Solargraph::Repo do
  context 'without a bundle' do
    let(:directory) { File.join('spec', 'fixtures', 'external_required_gem') }

    it 'finds system gems by name' do
      repo = described_class.new(directory)
      # Backport is an expected Solargraph dependency
      meta = repo.find_by_name('backport')
      expect(meta.name).to eq('backport')
    end

    it 'finds system gems by path' do
      repo = described_class.new(directory)
      # Backport is an expected Solargraph dependency
      meta = repo.find_by_path('backport/machine')
      expect(meta.name).to eq('backport')
    end
  end

  context 'with a bundle' do
    let(:directory) { File.join('spec', 'fixtures', 'external_bundled_gem') }

    it 'finds bundled gems by name' do
      repo = described_class.new(directory)
      expect(repo).to be_bundle
      meta = repo.find_by_name('backport')
      expect(meta.name).to eq('backport')
    end

    it 'finds bundled gems by path' do
      repo = described_class.new(directory)
      expect(repo).to be_bundle
      meta = repo.find_by_path('backport/machine')
      expect(meta.name).to eq('backport')
    end

    it 'finds path gems by name' do
      repo = described_class.new(directory)
      expect(repo).to be_bundle
      meta = repo.find_by_name('gem-with-yard-macros')
      expect(meta.name).to eq('gem-with-yard-macros')
    end

    it 'finds path gems by path' do
      repo = described_class.new(directory)
      expect(repo).to be_bundle
      meta = repo.find_by_path('gem/with/yard/macros')
      expect(meta.name).to eq('gem-with-yard-macros')
    end
  end
end
