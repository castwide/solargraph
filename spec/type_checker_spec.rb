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
