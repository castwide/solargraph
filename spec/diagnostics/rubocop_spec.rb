describe Solargraph::Diagnostics::Rubocop do
  it "diagnoses input" do
    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(%(
      class Foo
        def bar
        end
      end
      foo = Foo.new
    ), 'file.rb')
    expect(result).to be_a(Array)
  end

  it "returns a DiagnosticsError without an executable" do
    rubocop = Solargraph::Diagnostics::Rubocop.new('not_a_valid_executable')
    expect {
      rubocop.diagnose(%(
        puts 'hello'
      ), 'file.rb')
    }.to raise_error(Solargraph::DiagnosticsError)
  end
end
