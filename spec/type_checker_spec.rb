describe Solargraph::TypeChecker do
  it 'does not raise errors checking unparsed sources' do
    expect {
      checker = Solargraph::TypeChecker.load_string(%(
        foo{
      ))
      checker.problems
    }.not_to raise_error
  end
end
