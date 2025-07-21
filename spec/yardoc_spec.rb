# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::Yardoc do
  describe '#build_docs' do
    around do |testobj|
      @tmpdir = Dir.mktmpdir

      testobj.run
    ensure
      FileUtils.remove_entry(@tmpdir) # rubocop:disable RSpec/InstanceVariable
    end

    let(:gem_yardoc_path) do
      File.join(@tmpdir, 'solargraph', 'yardoc', 'test_gem') # rubocop:disable RSpec/InstanceVariable
    end

    describe '#processing?' do
      it 'returns true if the yardoc is being processed' do
        gem_yardoc_path = File.join(@tmpdir, 'yardoc')
        FileUtils.mkdir_p(gem_yardoc_path)
        FileUtils.touch(File.join(gem_yardoc_path, 'processing'))
        expect(Solargraph::Yardoc.processing?(gem_yardoc_path)).to be(true)
      end

      it 'returns false if the yardoc is not being processed' do
        gem_yardoc_path = File.join(@tmpdir, 'yardoc')
        FileUtils.mkdir_p(gem_yardoc_path)
        expect(Solargraph::Yardoc.processing?(gem_yardoc_path)).to be(false)
      end
    end

    it 'builds docs for a gem' do
      api_map = Solargraph::ApiMap.load(Dir.pwd)
      gemspec = api_map.find_gem('rubocop')
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end

    it 'is idempotent' do
      api_map = Solargraph::ApiMap.load(Dir.pwd)
      gemspec = api_map.find_gem('rubocop')
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end
  end
end
