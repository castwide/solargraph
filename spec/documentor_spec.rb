require 'tmpdir'

describe Solargraph::Documentor do
  before :all do
    Bundler.with_clean_env do
      Dir.chdir 'spec/fixtures/workspace' do
        `bundle install`
      end
    end
  end

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

  it 'documents bundles' do
    result = Solargraph::Documentor.new('spec/fixtures/workspace', rebuild: true, quiet: true).document
    expect(result).to be(true)
  end

  it 'reports failures to document bundles' do
    Dir.mktmpdir do |tmp|
      result = Solargraph::Documentor.new(tmp, rebuild: true).document
      expect(result).to be(false)
    end
  end
end
