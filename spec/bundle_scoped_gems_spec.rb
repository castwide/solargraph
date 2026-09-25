# frozen_string_literal: true

# `solargraph gems` with no arguments reads the current directory, in either
# cache design, and should document what that workspace can actually load
# rather than every gem version RubyGems can see.
describe Solargraph::Shell do
  let(:shell) { described_class.new }
  let(:directory) { File.expand_path(File.join('spec', 'fixtures', 'bundle-scoped-gems')) }

  # @return [Integer] the count the command reports
  def gems_in_fixture
    output = Dir.chdir(directory) { capture_both { shell.gems } }
    # "cached for all N gems" is the every-installed-gem wording.
    count = output[/cached for (?:all )?(\d+) gems/, 1]
    raise "no gem count in: #{output}" if count.nil?

    count.to_i
  end

  it 'documents fewer gems than RubyGems can see' do
    expect(gems_in_fixture).to be < Gem::Specification.to_a.size
  end

  it 'documents the gem the workspace bundle resolves' do
    gems_in_fixture

    pins = Solargraph::ApiMap.load(directory).get_path_pins('Backport')

    expect(pins).not_to be_empty
  end
end
