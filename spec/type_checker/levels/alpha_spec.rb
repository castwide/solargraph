# frozen_string_literal: true

describe Solargraph::TypeChecker do
  context 'when at alpha level' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :alpha)
    end
    it 'does not falsely enforce nil in return types' do
      pending('type inference fix')

      checker = type_checker(%(
      # @return [Integer]
      def foo
        # @sg-ignore
        # @type [Integer, nil]
        a = bar
        a || 123
      end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'reports nilable type issues' do
      checker = type_checker(%(
        # @param a [String]
        # @return [void]
        def foo(a); end

        # @param b [String, nil]
        # @return [void]
        def bar(b)
         foo(b)
        end
      ))
      expect(checker.problems.map(&:message))
        .to eq(['Wrong argument type for #foo: a expected String, received String, nil'])
    end
  end
end
