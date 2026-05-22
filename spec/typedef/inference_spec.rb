# frozen_string_literal: true

describe Solargraph::Typedef::Inference do
  it 'resolves generics' do
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def foo; end

      foo.first
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(4, 10, 4, 10))
    chain = Solargraph::Source::SourceChainer.chain(source, [4, 10])
    pins = Solargraph::Typedef::Inference.define_from_chain(chain, api_map, location)
    expect(pins.map(&:path)).to eq(['Array#first', 'Enumerable#first'])
  end

  it 'infers types' do
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def foo; end

      foo.first
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(4, 10, 4, 10))
    chain = Solargraph::Source::SourceChainer.chain(source, [4, 10])
    types = Solargraph::Typedef::Inference.infer_from_chain(chain, api_map, location)
    puts types.map(&:to_s)
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
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 17, 5, 17))
    chain = Solargraph::Source::SourceChainer.chain(source, [5, 17])
    pins = Solargraph::Typedef::Inference.define_from_chain(chain, api_map, location)
    expect(pins.map(&:path)).to eq(['Foo#bar'])
  end
end
