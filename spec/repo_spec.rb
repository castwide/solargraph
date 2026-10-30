# frozen_string_literal: true

require 'fileutils'

describe Solargraph::Repo do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.rm_f File.join('spec', 'fixtures', 'external_bundled_gem', 'Gemfile.lock')
    Solargraph.with_clean_env do
      `cd #{File.join('spec', 'fixtures', 'external_bundled_gem')} && bundle install`
    end
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.rm_f File.join('spec', 'fixtures', 'external_bundled_gem', 'Gemfile.lock')
  end

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
    let(:repo) { described_class.new(directory) }

    it 'tracks bundles' do
      expect(repo).to be_bundled
    end

    it 'finds bundled gems by name' do
      meta = repo.find_by_name('backport')
      expect(meta.name).to eq('backport')
    end

    it 'finds bundled gems by path' do
      meta = repo.find_by_path('backport/machine')
      expect(meta.name).to eq('backport')
    end

    it 'finds path gems by name' do
      meta = repo.find_by_name('gem-with-yard-macros')
      expect(meta.name).to eq('gem-with-yard-macros')
    end

    it 'finds path gems by path' do
      meta = repo.find_by_path('gem/with/yard/macros')
      expect(meta.name).to eq('gem-with-yard-macros')
    end

    it 'adds dependencies to metagems' do
      meta = repo.find_by_name('reverse_markdown')
      expect(meta.dependencies).to include('nokogiri')
    end

    it 'finds transitive gem dependencies' do
      # nokogiri is a transitive dependency of reverse_markdown
      meta = repo.find_by_name('nokogiri')
      expect(meta.name).to eq('nokogiri')
    end
  end
end
