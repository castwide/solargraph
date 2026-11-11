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
    context 'with inline rbs type assertions' do
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

      it 'does not apply the assertion to the next statement' do
        pending 'Inference required'
        expect(declare_at(%(
          x = 1 #: String
          y = 'y'.size
          y
        ), 3, 10)).to eq('Integer')
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
      typeset = dictionary_for(code, [9, 21]).declare
      expect(typeset.to_s).to eq('Integer')
    end
  end
end
