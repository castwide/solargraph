# frozen_string_literal: true

require 'rbs'

describe Solargraph::RbsMap2 do
  describe '#pins' do
    let(:rbs_map) do
      # language_server-protocol is a known transitive dependency with RBS definitions
      gemspec = Gem::Specification.find_by_name('language_server-protocol')
      metagem = Solargraph::Metagem.from_specification(gemspec)
      described_class.new(metagem)
    end

    it 'converts signatures to pins' do
      interface = rbs_map.pins.find { |pin| pin.path == 'LanguageServer::Protocol::Interface' }
      expect(interface).to be_a(Solargraph::Pin::Namespace)
    end
  end
end
