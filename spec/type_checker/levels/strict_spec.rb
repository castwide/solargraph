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

    it 'reports undefined method calls with defined roots' do
      checker = type_checker(%(
        String.new.not_a_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call signature')
    end

    it 'ignores undefined method calls from external sources' do
      # @todo This test uses Nokogiri because it's a gem dependency known to
      #   lack typed methods. A better test wouldn't depend on the state of
      #   vendored code.
      checker = type_checker(%(
        require 'nokogiri'
        Nokogiri::HTML.parse('code').undefined_call
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates existing param tags' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end
  end
end
