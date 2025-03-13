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

    it 'validates generic return types with non-generic arrays' do
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

    it 'validates generic return types with non-generic hashes' do
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
      # @todo This test might be invalid. There are use cases where inheritance
      #   between inferred and expected classes should be acceptable in either
      #   direction.
      # checker = type_checker(%(
      #   class Sup; end
      #   class Sub < Sup
      #     # @return [Sub]
      #     def foo
      #       Sup.new
      #     end
      #   end
      # ))
      # expect(checker.problems).to be_one
      # expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'validates generic subclasses of return types' do
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

    it 'ignores inferred types for abstract methods' do
      checker = type_checker(%(
        class Foo
          # @abstract
          # @return [String]
          def bar; end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates inferred types for overridden abstract methods' do
      checker = type_checker(%(
        class Foo
          # @abstract
          # @return [String]
          def bar; end
        end

        class Bar < Foo
          def bar
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'ignores inferred types for abstract classes' do
      checker = type_checker(%(
        # @abstract
        class Foo
          # @return [String]
          def bar; end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates subclasses of abstract classes' do
      checker = type_checker(%(
        # @abstract
        class Foo
          # @return [String]
          def bar; end
        end

        class Bar < Foo
          def bar
            100
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'handles mixin types with self types on init' do
      checker = type_checker(%(
        # @param a [Enumerable<String>]
        def bar(a = ['a']); end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports undefined param tags' do
      checker = type_checker(%(
        # @param bar [UndefinedClass]
        def foo(bar)
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved type UndefinedClass')
    end

    it 'validates included modules in types' do
      checker = type_checker(%(
        module Interface
        end
        class Host
          include Interface
        end
        # @type [Interface]
        host = Host.new
      ))
      expect(checker.problems).to be_empty
    end

    it 'invalidates modules not included in types' do
      checker = type_checker(%(
        module Interface
        end
        class Host
        end
        # @type [Interface]
        host = Host.new
      ))
      expect(checker.problems).to be_one
    end

    it 'validates duck type params' do
      checker = type_checker(%(
        # @param bar [#to_s]
        def foo(bar)
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'ignores return type errors in methods tagged @sg-ignore' do
      checker = type_checker(%(
        # @sg-ignore
        # @return [String]
        def foo
          100
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates constuctor arities when overridden by subtype' do
      checker = type_checker(%(
        class Foo
          # @param a [Integer]
          def initialize(a); end
        end
        class Bar < Foo; end
        Bar.new
      ))
      expect(checker.problems.map(&:message)).to eq(['Not enough arguments to Foo.new'])
    end

    it 'validates constuctor arities when not overridden by subtype' do
      checker = type_checker(%(
        class Foo
          # @param a [Integer]
          def initialize(a); end
        end
        class Bar < Foo; end
        Bar.new(1)
      ))
      expect(checker.problems).to be_empty
    end
  end
end
