# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Yardoc do
  around do |testobj|
    @tmpdir = Dir.mktmpdir

    testobj.run
  ensure
    FileUtils.remove_entry(@tmpdir) # rubocop:disable RSpec/InstanceVariable
  end

  let(:gem_yardoc_path) do
    File.join(@tmpdir, 'solargraph', 'yardoc', 'test_gem') # rubocop:disable RSpec/InstanceVariable
  end

  before do
    FileUtils.mkdir_p(gem_yardoc_path)
  end

  describe '#processing?' do
    it 'returns true if the yardoc is being processed' do
      FileUtils.touch(File.join(gem_yardoc_path, 'processing'))
      expect(described_class.processing?(gem_yardoc_path)).to be(true)
    end

    it 'returns false if the yardoc is not being processed' do
      expect(described_class.processing?(gem_yardoc_path)).to be(false)
    end
  end

  describe '#build_docs' do
    let(:api_map) { Solargraph::ApiMap.load(Dir.pwd) }
    let(:gemspec) { api_map.find_gem('rubocop') }
    let(:output) { '' }

    before do
      allow(Solargraph.logger).to receive(:warn)
      allow(Solargraph.logger).to receive(:info)
    end

    it 'builds docs for a gem' do
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end

    it 'is idempotent' do
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      described_class.build_docs(gem_yardoc_path, [], gemspec) # second time
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end

    context 'with an error from yard' do
      before do
        allow(Open3).to receive(:capture2e).and_return([output, result])
      end

      let(:result) { instance_double(Process::Status) }

      it 'does not raise on error from yard' do
        allow(result).to receive(:success?).and_return(false)

        expect do
          described_class.build_docs(gem_yardoc_path, [], gemspec)
        end.not_to raise_error
      end
    end
  end
end
