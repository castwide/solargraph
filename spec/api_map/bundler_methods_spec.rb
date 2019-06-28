require 'tmpdir'
require 'fileutils'

describe Solargraph::ApiMap::BundlerMethods do
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
