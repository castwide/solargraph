describe Solargraph::TypeChecker do
  context 'typed level' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :typed)
    end

    it 'reports mismatched types for empty methods' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          def bar; end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'ignores attributes with return tags' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched return tags' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          def bar
            'string'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'reports mismatched inherited return tags' do
      checker = type_checker(%(
        class Sup
          # @return [String]
          def name
            'sup'
          end
        end

        class Sub < Sup
          def name
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'reports mismatched return tags from mixins' do
      checker = type_checker(%(
        module Mixin
          # @return [String]
          def name
            'sup'
          end
        end

        class Thing
          include Mixin

          def name
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'validates boolean return types' do
      checker = type_checker(%(
        class Foo
          # @return [Boolean]
          def bar
            1 == 2
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched type tags' do
      checker = type_checker(%(
        # @type [Integer]
        x = 'string'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'reports mismatched boolean return types' do
      checker = type_checker(%(
        class Foo
          # @return [Boolean]
          def bar
            'true'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match')
    end

    it 'infers self from virtual new methods' do
      checker = type_checker(%(
        class Butt
          def initialize
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates parameterized return types with unparameterized arrays' do
      checker = type_checker(%(
        class Foo
          # @return [Array<String>]
          def bar
            []
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates parameterized return types with unparameterized hashes' do
      checker = type_checker(%(
        class Foo
          # @return [Hash{String => Integer}]
          def bar
            {}
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates subclasses of return types' do
      checker = type_checker(%(
        class Sup; end
        class Sub < Sup
          # @return [Sup]
          def foo
            Sub.new
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports superclasses of return types' do
      checker = type_checker(%(
        class Sup; end
        class Sub < Sup
          # @return [Sub]
          def foo
            Sup.new
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'validates parameterized subclasses of return types' do
      checker = type_checker(%(
        class Sup; end
        class Sub < Sup
          # @return [Class<Sup>]
          def foo
            Sub
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates subclass arguments of param types' do
      checker = type_checker(%(
        class Sup
          # @param other [Sup]
          # @return [void]
          def take(other); end
        end
        class Sub < Sup; end
        Sup.new.take(Sub.new)
        ))
      expect(checker.problems).to be_empty
    end

    it 'resolves self when validating inferred types' do
      checker = type_checker(%(
        class Foo
          # @return [self]
          def bar
            Foo.new
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'allows loose return tags' do
      checker = type_checker(%(
        class Foo
          # The tag is [String] but the inference is [String, nil]
          #
          # @return [String]
          def bar
            false ? 'bar' : nil
          end
        end
      ))
      expect(checker.problems).to be_empty
    end
  end
end
