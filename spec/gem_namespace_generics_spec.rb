# frozen_string_literal: true

# simplecov declares SimpleCov::Filter in Ruby source with no type parameter,
# and the RBS collection declares it as Filter[T]. Both descriptions have to
# end up on one pin or the generic is lost. This workspace already has both,
# so the assertion needs no fixture of its own.
describe Solargraph::ApiMap do
  let(:filter_pins) { described_class.load_with_cache('.', nil).get_path_pins('SimpleCov::Filter') }

  before do
    # Whatever built a kept entry decided then how the two descriptions
    # combine, so it would answer for that code rather than this.
    Solargraph::Shell.new.uncache('simplecov')
  end

  it 'resolves the class to a single pin' do
    expect(filter_pins.size).to eq(1)
  end

  it "keeps the type parameter only the gem's RBS declares" do
    expect(filter_pins.first.generics).to eq(['T'])
  end
end
