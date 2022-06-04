describe Solargraph::TypeChecker do
  it 'does not raise errors checking unparsed sources' do
    expect {
      checker = Solargraph::TypeChecker.load_string(%(
        foo{
      ))
      checker.problems
    }.not_to raise_error
  end

  it 'ignores tagged problems' do
    checker = Solargraph::TypeChecker.load_string(%(
      NotAClass

      # @sg-ignore
      NotAClass
    ), nil, :strict)
    expect(checker.problems).to be_one
  end
end
