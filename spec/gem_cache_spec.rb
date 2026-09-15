# frozen_string_literal: true

describe Solargraph::GemCache do
  let(:gemspec) { Gem::Specification.find_by_name('backport') }
  let(:metagem) { Solargraph::Metagem.from_specification(gemspec) }

  before(:each) { described_class.cache(metagem) }

  it 'caches metagem pins' do
    expect(described_class.exist?(metagem)).to be(true)
    # @todo expectations
  end

  it 'uncaches metagem pins' do
    described_class.uncache(metagem)
    expect(described_class.exist?(metagem)).to be(false)
  end

  it 'loads metagem pins' do
    described_class.load(metagem)
    # @todo expectations
  end

  it 'gets file locations from combined pins' do
    # language_server-protocol is a known transitive dependency with RBS definitions
    gemspec = Gem::Specification.find_by_name('language_server-protocol')
    metagem = Solargraph::Metagem.from_specification(gemspec)
    described_class.save(metagem) unless described_class.exist?(metagem)
    pins = described_class.load(metagem)
    interface = pins.find { |pin| pin.path == 'LanguageServer::Protocol::Interface' }
    expect(interface.location.filename).to end_with('lib/language_server/protocol/interface.rb')
  end
end
