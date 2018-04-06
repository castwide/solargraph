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
end
