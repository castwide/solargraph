# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Yardoc do
  let(:gem_yardoc_path) do
    Solargraph::PinCache.yardoc_path gemspec
  end

  before do
    FileUtils.mkdir_p(gem_yardoc_path)
  end

  describe '#cache' do
    let(:api_map) { Solargraph::ApiMap.new }
    let(:doc_map) { api_map.doc_map }
    let(:gemspec) { Gem::Specification.find_by_path('rubocop') }
    let(:output) { '' }

    before do
      allow(Solargraph.logger).to receive(:warn)
      allow(Solargraph.logger).to receive(:info)
      FileUtils.rm_rf(gem_yardoc_path)
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

        described_class.cache([], gemspec)

        expect(called_with[0]['BUNDLE_GEMFILE']).to start_with('/')
      end
    end
  end
end
