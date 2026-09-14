# frozen_string_literal: true

describe Solargraph::GemCache do
  let(:gemspec) { Gem::Specification.find_by_name('backport') }
  let(:metagem) { Solargraph::Metagem.from_specification(gemspec) }

  it 'saves' do
    described_class.save(metagem)
    # @todo expectations
  end

  it 'loads' do
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
