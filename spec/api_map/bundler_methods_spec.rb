require 'tmpdir'
require 'fileutils'

describe Solargraph::ApiMap::BundlerMethods do
  # @todo Skipping Bundler-related tests on JRuby
  next if RUBY_PLATFORM == 'java'

  # Build the Gemfile.lock in specs so Travis jobs use the correct version of
  # Bundler (e.g., Ruby 2.1 uses Bundler 1)
  before :all do
    Dir.chdir 'spec/fixtures/workspace' do
      `bundle install`
    end
  end

  after :all do
    File.unlink 'spec/fixtures/workspace/Gemfile.lock'
  end

  after :each do
    Solargraph::ApiMap::BundlerMethods.reset_require_from_bundle
  end

  it 'finds default gems from bundler/require' do
    result = Solargraph::ApiMap::BundlerMethods.require_from_bundle('spec/fixtures/workspace')
    expect(result.keys).to eq(['backport', 'bundler'])
  end

  it 'does not raise an error without a bundle' do
    expect {
      Dir.mktmpdir do |dir|
        Bundler.with_clean_env do
          Solargraph::ApiMap::BundlerMethods.require_from_bundle(dir)
        end
      end
    }.not_to raise_error
  end
end
