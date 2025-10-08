# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Yardoc do
  around do |testobj|
    @tmpdir = Dir.mktmpdir

    testobj.run
  ensure
    FileUtils.remove_entry(@tmpdir)
  end

  let(:gem_yardoc_path) do
    File.join(@tmpdir, 'solargraph', 'yardoc', 'test_gem')
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

  describe '#load!' do
    it 'does not blow up when called on empty directory' do
      expect { described_class.load!(gem_yardoc_path) }.not_to raise_error
    end
  end

  describe '#build_docs' do
    let(:workspace) { Solargraph::Workspace.new(Dir.pwd) }
    let(:gemspec) { workspace.find_gem('rubocop') }
    let(:output) { '' }

    before do
      allow(Solargraph.logger).to receive(:warn)
      allow(Solargraph.logger).to receive(:info)
      FileUtils.rm_rf(gem_yardoc_path)
    end

    it 'builds docs for a gem' do
      described_class.build_docs(gem_yardoc_path, [], gemspec)
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end

    it 'bails quietly if directory given does not exist' do
      allow(File).to receive(:exist?).and_return(false)

      expect do
        described_class.build_docs(gem_yardoc_path, [], gemspec)
      end.not_to raise_error
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

    context 'when given a relative BUNDLE_GEMFILE path' do
      around do |example|
        # turn absolute BUNDLE_GEMFILE path into relative
        existing_gemfile = ENV.fetch('BUNDLE_GEMFILE', nil)
        current_dir = Dir.pwd
        # remove prefix current_dir from path
        ENV['BUNDLE_GEMFILE'] = existing_gemfile.sub("#{current_dir}/", '')
        raise 'could not figure out relative path' if Pathname.new(ENV.fetch('BUNDLE_GEMFILE', nil)).absolute?
        example.run
        ENV['BUNDLE_GEMFILE'] = existing_gemfile
      end

      it 'sends Open3 an absolute path' do
        called_with = nil
        allow(Open3).to receive(:capture2e) do |*args|
          called_with = args
          ['output', instance_double(Process::Status, success?: true)]
        end

        described_class.build_docs(gem_yardoc_path, [], gemspec)

        expect(called_with[0]['BUNDLE_GEMFILE']).to start_with('/')
      end
    end
  end
end
