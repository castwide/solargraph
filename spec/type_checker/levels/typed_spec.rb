describe Solargraph::TypeChecker do
  context 'typed level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :typed)
    end

    it 'reports methods without either return tags or inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            unknown_method
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'reports untyped methods without inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            unknown_method
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'ignores untyped methods with inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            Array.new
          end
        end
      ))
      expect(checker.problems).to be_empty
    end
  end
end