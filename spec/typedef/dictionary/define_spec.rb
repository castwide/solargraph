describe Solargraph::Typedef::Dictionary do
  def dictionary_for code, position
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    described_class.new(api_map, 'test.rb', position)
  end

  describe '#define' do
    it 'resolves methods with parameters' do
      code = %(
        # @return [Array<String>]
        def foo; end

        foo.first
      )

      pins = dictionary_for(code, [4, 12]).define
      expect(pins.map(&:path)).to eq(['Array#first', 'Enumerable#first'])
    end

    it 'resolves self' do
      code = %(
        class Foo
          def bar; end

          def baz
            self.bar
          end
        end
      )

      pins = dictionary_for(code, [5, 19]).define
      expect(pins.map(&:path)).to eq(['Foo#bar'])
    end

    it 'expands named macros' do
      code = %(
        # @!macro [new] klassify
        #   @return [Array<$1>]
        class Example
          # @macro klassify
          def foo(klass)
          end
        end
      )

      pins = dictionary_for(code, [5, 14]).define
      expect(pins.first.typedef_typeset.to_s).to eq('Array[klass]')
    end

    it 'follows constant chains' do
      code = %(
        module Mixin; end
        module Container
          class Foo; end
        end
        Container::Foo::Mixin
      )

      pins = dictionary_for(code, [5, 25]).define
      expect(pins).to be_empty
    end

    it 'rebases inner constants chains' do
      code = %(
        class Foo
          class Bar; end
          ::Foo::Bar
        end
      )

      pins = dictionary_for(code, [3, 18]).define
      expect(pins.first.path).to eq('Foo::Bar')
    end

    it 'resolves relative constant paths' do
      code = %(
        class Foo
          class Bar
            class Baz; end
          end
          module Other
            Bar::Baz
          end
        end
      )

      pins = dictionary_for(code, [6, 18]).define
      expect(pins.first.path).to eq('Foo::Bar::Baz')
    end

    it 'avoids recursive variable assignments' do
      code = %(
        @foo = @bar
        @bar = @foo.quz
      )

      dictionary = dictionary_for(code, [2, 20])
      expect { dictionary.define }.not_to raise_error
    end

    it 'matches constants on complete symbols' do
      code = %(
        class Correct; end
        class NotCorrect; end
        Correct
      )

      pins = dictionary_for(code, [3, 8]).define
      expect(pins.map(&:path)).to eq(['Correct'])
    end
  end
end
