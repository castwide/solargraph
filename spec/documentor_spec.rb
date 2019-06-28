require 'tmpdir'

describe Solargraph::Documentor do
  after :all do
    File.unlink 'spec/fixtures/workspace/Gemfile.lock'
  end

  it 'returns gemsets for directories with bundles' do
    gemset = Solargraph::Documentor.specs_from_bundle('spec/fixtures/workspace')
    expect(gemset.keys).to eq(['backport', 'bundler'])
  end

  it 'raises errors for directories without bundles' do
    Dir.mktmpdir do |tmp|
      expect {
        Solargraph::Documentor.specs_from_bundle(tmp)
      }.to raise_error(Solargraph::BundleNotFoundError)
    end
  end
end
