# frozen_string_literal: true

describe Solargraph::External do
  before :each do
    metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport'))
    Solargraph::GemCache.save(metagem) unless Solargraph::GemCache.exist?(metagem)
  end

  it 'works' do
    library = Solargraph::Library.load(File.join('spec', 'fixtures', 'external_bundled_gem'))
    library.map!
    external = described_class.new(library.bench)
    # @todo expectations
  end
end
