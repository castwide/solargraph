# frozen_string_literal: true

require 'rbs'

describe Solargraph::RbsMap2 do
  describe '#pins' do
    it 'converts signatures' do
      gemspec = Gem::Specification.find_by_name('rbs')
      metagem = Solargraph::Metagem.from_specification(gemspec)
      rbs_map = described_class.new(metagem)
      # @todo Spot check some pins
    end
  end
end
