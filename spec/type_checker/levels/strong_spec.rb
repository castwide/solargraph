describe Solargraph::TypeChecker do
  context 'strong level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strong)
    end

    it 'reports missing return tags' do
      checker = type_checker(%(
        class Foo
          def bar
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @return tag')
    end

    it 'reports missing param tags' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar baz
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing @param tag')
    end

    it 'ignores optional params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar *args
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores optional keyword params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar **opts
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores untagged block params' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar &block
          end
        end
      ))
      expect(checker.problems).to be_empty
    end
  end
end
