require 'tmpdir'
require 'open3'

describe Solargraph::Documentor do
  # @todo Skipping Bundler-related tests on JRuby
  next if RUBY_PLATFORM == 'java'

  it 'returns gemsets for directories with bundles' do
    gemset = Solargraph::Documentor.specs_from_bundle('spec/fixtures/workspace-with-gemfile')
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
    result = Solargraph::Documentor.new('spec/fixtures/workspace-with-gemfile', rebuild: true).document
    expect(result).to be(true)
  end

  it 'reports failures to document bundles' do
    Dir.mktmpdir do |tmp|
      result = Solargraph::Documentor.new(tmp, rebuild: true).document
      expect(result).to be(false)
    end
  end
end
