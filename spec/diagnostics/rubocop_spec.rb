describe Solargraph::Diagnostics::Rubocop do
  before :each do
    @source = Solargraph::Source.new(%(
      class Foo
        def bar
        end
      end
      foo = Foo.new
    ), 'file.rb')

    @api_map = Solargraph::ApiMap.new
    @api_map.virtualize @source
  end

  it "diagnoses input" do
    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(@source, @api_map)
    expect(result).to be_a(Array)
  end

  it "raises a DiagnosticsError without a valid executable" do
    rubocop = Solargraph::Diagnostics::Rubocop.new('not_a_valid_executable')
    expect {
      rubocop.diagnose(@source, @api_map)
    }.to raise_error(Solargraph::DiagnosticsError)
  end
end
