describe Solargraph::Typedef::Dictionary do
  def dictionary_for code, position
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    described_class.at(api_map, 'test.rb', position)
  end

  def declare_at(code, line, char)
    dictionary_for(code, [line, char]).declare.to_s
  end

  describe '#declare' do
    context 'without type declarations' do
      it 'does not infer from variable assignments' do
        code = 'x = Object.new'
        typeset = dictionary_for(code, [0, 0]).declare
        expect(typeset).to be_undefined
      end

      it 'does not infer from literals' do
        code = 'x = 1'
        typeset = dictionary_for(code, [0, 0]).declare
        expect(typeset).to be_undefined
      end

      it 'expands self from Array#new' do
        code = 'Array.new'
        typeset = dictionary_for(code, [0, 6]).declare
        expect(typeset.to_s).to eq('Array')
      end

      it 'expands self from new subclass calls without a subclass initialize method' do
        code = %(
          class Sup
            def initialize; end
            def meth; end
          end
          class Sub < Sup
            def meth; end
          end

          Sub.new
        )

        typeset = dictionary_for(code, [9, 14]).declare
        expect(typeset.to_s).to eq('Sub')
      end

      it 'expands self from inherited Object#freeze' do
        code = %(
          Array.new.freeze
        )

        typeset = dictionary_for(code, [1, 20]).declare
        expect(typeset.to_s).to eq('Array')
      end
    end

    context 'with inline RBS type assertions' do
      it 'types local variables' do
        expect(declare_at(%(
          x = [] #: Array[String]
          x
        ), 2, 10)).to eq('Array[String]')
      end

      it 'types instance variables' do
        expect(declare_at(%(
          class Foo
            def initialize
              @bar = {} #: Hash[String, Integer]
            end

            def baz
              @bar
            end
          end
        ), 7, 14)).to eq('Hash[String, Integer]')
      end

      it 'types class variables' do
        expect(declare_at(%(
          class Foo
            @@bar = nil #: String?

            def baz
              @@bar
            end
          end
        ), 5, 14)).to eq('String | nil')
      end

      it 'types global variables' do
        expect(declare_at(%(
          $foo = [] #: Array[Integer]
          $foo
        ), 2, 10)).to eq('Array[Integer]')
      end

      it 'types variables initialized as tuples' do
        pending 'Tuple support'
        expect(declare_at(%(
          pair = ['a', 1] #: [String, Integer]
          pair
        ), 2, 10)).to eq('Array(String, Integer)')
      end

      it 'types variables initialized from hash literals' do
        expect(declare_at(%(
          opts = { 'a' => 1 } #: Hash[String, Integer]
          opts
        ), 2, 10)).to eq('Hash[String, Integer]')
      end

      it 'types ||= assignments' do
        expect(declare_at(%(
          x ||= [] #: Array[String]
          x
        ), 2, 10)).to eq('Array[String]')
      end

      it 'types assignments that span lines' do
        expect(declare_at(%(
          x = [
            'a'
          ] #: Array[String]
          x
        ), 4, 10)).to eq('Array[String]')
      end

      it 'prefers the assertion over a @type tag' do
        expect(declare_at(%(
          # @type [Array<Integer>]
          x = [] #: Array[String]
          x
        ), 3, 10)).to eq('Array[String]')
      end

      it 'ignores comments that are not valid RBS types' do
        pending 'Inference required'
        expect(declare_at(%(
          x = 'x'.size #:nodoc:
          x
        ), 2, 10)).to eq('Integer')
      end

      it 'ignores #: inside string literals' do
        pending 'Inference required'
        expect(declare_at(%(
          x = '#: Integer'
          x
        ), 2, 10)).to eq('String')
      end

      it 'types operator assignments' do
        expect(declare_at(%(
          x = 0
          x += 1 #: Float
          x
        ), 3, 10)).to eq('Float')
      end

      it 'types variables with union types' do
        expect(declare_at(%(
          x = nil #: String | Integer
          x
        ), 2, 10)).to eq('String | Integer')
      end

      it 'types values of nested generic hashes' do
        expect(declare_at(%(
          h = {} #: Hash[Symbol, Array[String]]
          h[:a]
        ), 2, 15)).to eq('Array[String] | nil')
      end

      it 'types variables with qualified names in a namespace' do
        expect(declare_at(%(
          module Top
            class Bar; end

            class Foo
              def baz
                x = nil #: Top::Bar
                x
              end
            end
          end
        ), 7, 16)).to eq('Top::Bar')
      end

      it 'types variables with names relative to a namespace' do
        expect(declare_at(%(
          module Top
            class Bar; end

            class Foo
              def baz
                x = nil #: Bar
                x
              end
            end
          end
        ), 7, 16)).to eq('Top::Bar')
      end

      it 'types variables with record types as hashes' do
        expect(declare_at(%(
          cfg = { name: 'app' } #: { name: String }
          cfg
        ), 2, 10)).to eq('Hash')
      end

      it 'types values of record types' do
        pending('record type support')

        expect(declare_at(%(
          cfg = { name: 'app' } #: { name: String }
          cfg[:name]
        ), 2, 20)).to eq('String')
      end

      it 'types elements of tuples' do
        pending('literal index typing, disabled by castwide/solargraph#1201')

        expect(declare_at(%(
          pair = ['a', 1] #: [String, Integer]
          pair[0]
        ), 2, 17)).to eq('String')
      end
    end

    context 'with YARD tags' do
      it 'gets variable type tags' do
        code = %(
          # @type [Array<String>]
          x = foo
        )
        typeset = dictionary_for(code, [2, 10]).declare
        expect(typeset.to_s).to eq('Array[String]')
      end

      it 'gets modified types from inherited methods' do
        code = %(
          class Superclass
            # @return [String]
            def foo; end
          end
          class Subclass < Superclass
            # @return [Integer]
            def foo; end
          end
          Subclass.new.foo
        )
        typeset = dictionary_for(code, [9, 23]).declare
        expect(typeset.to_s).to eq('Integer')
      end

      it 'gets types from generics' do
        code = %(
          # @return [Array<String>]
          def foo; end

          foo.first
        )

        typeset = dictionary_for(code, [4, 14]).declare
        expect(typeset.to_s).to eq('String | nil')
      end

      it 'resolves an RBS self return type to the union member that supplied the method' do
        code = %(
          # @type [String, Symbol]
          name = string_or_symbol
          name.to_sym
        )

        typeset = dictionary_for(code, [3, 15]).declare
        expect(typeset.to_s).to eq('Symbol')
      end

      it 'resolves a shared self-returning method separately for each union member' do
        code = %(
          # @type [String, Symbol]
          name = string_or_symbol
          name.itself
        )

        typeset = dictionary_for(code, [3, 15]).declare
        expect(typeset.to_s).to eq('String | Symbol')
      end

      it 'resolves self in a union return type separately for each union member' do
        code = %(
          class Base
            # @return [String, self]
            def pick; end
          end

          class Alpha < Base; end
          class Beta < Base; end

          # @type [Alpha, Beta]
          thing = alpha_or_beta
          thing.pick
        )

        typeset = dictionary_for(code, [11, 17]).declare
        expect(typeset.to_s).to eq('String | Alpha | Beta')
      end

      it 'resolves a YARD @return [self] to the union member that supplied the method' do
        code = %(
          class Alpha
            # @return [Symbol]
            def to_thing; end
          end

          class Beta
            # @return [self]
            def to_thing; end
          end

          # @type [Alpha, Beta]
          thing = alpha_or_beta
          thing.to_thing
        )

        typeset = dictionary_for(code, [13, 16]).declare
        expect(typeset.to_s).to eq('Symbol | Beta')
      end

      it 'distributes a YARD self nested in a generic across union members' do
        pending 'WIP'
        code = %(
          class Base
            # @return [Array<self>]
            def many; end
          end

          class Alpha < Base; end
          class Beta < Base; end

          # @type [Alpha, Beta]
          thing = alpha_or_beta
          thing.many
        )

        typeset = dictionary_for(code, [11, 18]).declare
        expect(typeset.to_s).to eq('Array[Alpha], Array[Beta]')
      end

      it 'does not leak one union member into a Class#new call resolved on another' do
        code = %(
          class Beta; end

          # @type [Class<Beta>, Class]
          klass = beta_class_or_generic_class
          klass.new
        )

        typeset = dictionary_for(code, [5, 17]).declare
        # The bare `Class` member cannot know what its #new constructs, and Beta must not leak in from the other.
        expect(typeset.to_s).to eq('undefined')
      end

      it 'resolves Class#new the same way regardless of union member order' do
        code = %(
          class Beta; end

          # @type [Class, Class<Beta>]
          klass = generic_or_beta_class
          klass.new
        )

        typeset = dictionary_for(code, [5, 16]).declare
        expect(typeset.to_s).to eq('undefined')
      end
    end
  end
end
