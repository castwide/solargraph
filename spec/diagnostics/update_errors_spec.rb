describe Solargraph::Diagnostics::UpdateErrors do
  it "detects repaired lines" do
    api_map = Solargraph::ApiMap.new
    orig = Solargraph::Source.load_string('foo', 'test.rb')
    diagnoser = Solargraph::Diagnostics::UpdateErrors.new
    result = diagnoser.diagnose(orig, api_map)
    expect(result.length).to eq(0)
    updater = Solargraph::Source::Updater.new('test.rb', 2, [
      Solargraph::Source::Change.new(
        Solargraph::Range.from_to(0, 3, 0, 3),
        '.'
      )
    ])
    source = orig.synchronize(updater)
    diagnoser = Solargraph::Diagnostics::UpdateErrors.new
    result = diagnoser.diagnose(source, api_map)
    expect(result.length).to eq(1)
  end
end
