# frozen_string_literal: true

describe Solargraph::External do
  it 'works' do
    library = Solargraph::Library.load(File.join('spec', 'fixtures', 'external_bundled_gem'))
    library.map!
    external = described_class.new(library.bench)
  end
end
