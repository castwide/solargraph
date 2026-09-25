# frozen_string_literal: true

# A gem can describe the same class twice -- once in Ruby source that YARD
# reads, once in RBS -- and only the RBS carries generics. Both descriptions
# have to end up on one pin, or the generics are lost. ApiMap.load_with_cache
# is where a workspace asks, whichever layer merges them underneath.
describe Solargraph::ApiMap do
  let(:directory) { File.join('spec', 'fixtures', 'gem-namespace-generics') }
  let(:server_pins) { described_class.load_with_cache(directory, nil).get_path_pins('Backport::Server') }

  before do
    # Whatever built a kept entry decided then how the two descriptions
    # combine, so it would answer for that code rather than this.
    Solargraph::Shell.new.uncache('backport')
  end

  it 'resolves the class to a single pin' do
    expect(server_pins.size).to eq(1)
  end

  it "keeps the generics only the gem's RBS declares" do
    expect(server_pins.first.generics).to eq(['T'])
  end
end
