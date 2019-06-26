require 'tmpdir'
require 'fileutils'

describe Solargraph::ApiMap::BundlerMethods do
  describe 'with Gemfile.lock' do
    before :all do
      `cd spec/fixtures/workspace && bundle install`
    end

    after :all do
      File.unlink 'spec/fixtures/workspace/Gemfile.lock'
    end

    it 'finds default gems from bundler/require' do
      result = Solargraph::ApiMap::BundlerMethods.require_from_bundle('spec/fixtures/workspace')
      expect(result).to eq(['backport', 'bundler'])
      expect(Bundler.environment.specs.map(&:name)).to include('solargraph')
    end

    it 'does not raise an error processing bundler/require without a base Bundler environment' do
      Dir.mktmpdir do |tmp|
        Dir.chdir tmp do
          expect {
            Solargraph::ApiMap::BundlerMethods.require_from_bundle(tmp)
          }.not_to raise_error
        end
      end
    end
  end

  describe 'without Gemfile.lock' do
    before :all do
      @dir = Dir.mktmpdir
    end

    after :all do
      FileUtils.remove_entry @dir
    end

    it 'does not raise an error' do
      expect {
        Bundler.with_clean_env do
          Solargraph::ApiMap::BundlerMethods.require_from_bundle(@dir)
        end
      }.not_to raise_error
    end
  end
end
