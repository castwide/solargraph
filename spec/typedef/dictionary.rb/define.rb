describe Solargraph::Typedef::Dictionary do
  describe '#define' do
    it 'resolves methods with parameters' do
      source = Solargraph::Source.load_string(%(
        # @return [Array<String>]
        def foo; end

        foo.first
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [4, 12])
      pins = dictionary.define
      expect(pins.map(&:path)).to eq(['Array#first', 'Enumerable#first'])
    end

    it 'resolves self' do
      source = Solargraph::Source.load_string(%(
        class Foo
          def bar; end

          def baz
            self.bar
          end
        end
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)
      dictionary = described_class.new(api_map, 'test.rb', [5, 19])
      pins = dictionary.define
      expect(pins.map(&:path)).to eq(['Foo#bar'])
    end

    it 'expands named macros' do
      source = Solargraph::Source.load_string(%(
        # @!macro [new] klassify
        #   @return [Array<$1>]
        class Example
          # @macro klassify
          def foo(klass)
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new.map(source)
      api_map.get_path_pins('Example#foo').first
      dictionary = described_class.new(api_map, 'test.rb', [5, 14])
      defined = dictionary.define.first
      expect(defined.typedef_typeset.to_s).to eq('Array[klass]')
    end
  end
end
