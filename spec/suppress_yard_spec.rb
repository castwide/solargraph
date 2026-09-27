# frozen_string_literal: true

# Reproduction of castwide/solargraph#1339 against the post-1369 design.
# Yardoc.load! is the step that runs `yardoc` and is reached unconditionally
# whichever implementation is caching the gem.
describe Solargraph::Shell do
  let(:shell) do
    described_class.new.tap do |cli|
      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(
        'rebuild' => true, 'directory' => Dir.pwd
      )
    end
  end

  before do
    capture_both { shell.uncache('parser', 'backport') }
    allow(Solargraph::Yardoc).to receive(:load!).and_call_original
  end

  it 'reads no YARD documentation for the gem' do
    capture_both { shell.cache('parser') }

    expect(Solargraph::Yardoc).not_to have_received(:load!)
  end

  it 'still resolves the types the gem RBS declares' do
    capture_both { shell.cache('parser') }
    pins = Solargraph::ApiMap.load('.').get_path_pins('Parser::AST::Node#children')

    expect(pins.map { |pin| pin.return_type.to_s }).to include('Array<self>')
  end

  it 'reads YARD documentation for a gem outside the list' do
    capture_both { shell.cache('backport') }

    expect(Solargraph::Yardoc).to have_received(:load!)
  end

  it 'reads no YARD documentation when caching the gem by name' do
    capture_both { shell.gems('parser') }

    expect(Solargraph::Yardoc).not_to have_received(:load!)
  end

  it 'reads YARD documentation when caching a gem outside the list by name' do
    capture_both { shell.gems('backport') }

    expect(Solargraph::Yardoc).to have_received(:load!)
  end
end
