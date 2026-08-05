# frozen_string_literal: true

require 'timeout'

describe Solargraph::TypeChecker do
  it 'does not raise errors checking unparsed sources' do
    expect do
      checker = described_class.load_string(%(
        foo{
      ))
      checker.problems
    end.not_to raise_error
  end

  it 'ignores tagged problems' do
    checker = described_class.load_string(%(
      NotAClass

      # @sg-ignore
      NotAClass
    ), nil, :strict)
    expect(checker.problems).to be_one
  end

  # Regression test for https://github.com/castwide/solargraph/pull/1259#issuecomment-5192216269
  #
  # call_problems iterates every call node in a file and infers each one
  # with no rescue around it, so any exception raised deep inside a single
  # call's type inference (a ComplexTypeError from a malformed type, or any
  # other internal error) aborts TypeChecker#problems entirely instead of
  # being reported as a problem for that one call site, silently losing
  # every diagnostic for the rest of the file (and, when called per-file
  # across a workspace, every file after it).
  it 'reports a problem instead of aborting the whole run when inferring a single call raises' do
    checker = described_class.load_string(%(
      boom_call
      another_undefined_call
    ), nil, :strict)
    allow(Solargraph::Parser).to receive(:chain).and_wrap_original do |original, *args|
      chain = original.call(*args)
      allow(chain).to receive(:infer).and_raise(Solargraph::ComplexTypeError, 'boom') if chain.links.last.word == 'boom_call'
      chain
    end

    problems = nil
    expect { problems = checker.problems }.not_to raise_error
    expect(problems.map(&:message).join).to include('another_undefined_call')
  end

  it 'uses caching in Solargraph::Chain to handle a degenerate case' do
    checker = described_class.load_string(%(
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
    Timeout.timeout(5) do # seconds
      checker.problems
      timed_out = false
    end
    expect(timed_out).to be false
  end
end
