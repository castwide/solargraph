require 'tmpdir'

describe Solargraph::ApiMap::BundlerMethods do
  it 'finds default gems from bundler/require' do
    result = Solargraph::ApiMap::BundlerMethods.require_from_bundle('spec/fixtures/workspace')
    expect(result).to eq(['backport', 'bundler'])
    expect(Bundler.environment.specs.map(&:name)).to include('solargraph')
  end

  it 'does not raise an error processing bundler/require without a Gemfile' do
    Dir.mktmpdir do |tmp|
      expect {
        Solargraph::ApiMap::BundlerMethods.require_from_bundle(tmp)
      }.not_to raise_error
    end
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
