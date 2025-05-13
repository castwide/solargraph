require 'timeout'

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

  it 'uses caching in Solargraph::Chain to handle a degenerate case' do
    checker = Solargraph::TypeChecker.load_string(%(
      def documentation
        @documentation = "a"
        @documentation += "b"
        @documentation += "c"
        @documentation += "d"
        @documentation += "e"
        @documentation += "f"
        @documentation += "g"
        @documentation += "h"
        @documentation += "i"
        @documentation += "j"
        @documentation += "k"
        @documentation.to_s
      end
    ), nil, :strict)
    timed_out = true
    Timeout::timeout(5) do # seconds
      checker.problems
      timed_out = false
    end
    expect(timed_out).to be false
  end
end
