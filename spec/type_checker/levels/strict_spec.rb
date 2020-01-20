describe Solargraph::TypeChecker do
  context 'strict level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strict)
    end

    it 'ignores method calls with inferred types' do
      checker = type_checker(%(
        String.new.upcase
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports method calls without inferred types' do
      checker = type_checker(%(
        unknown_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call signature')
    end
  end
end
