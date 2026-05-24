# frozen_string_literal: true

describe Solargraph::Typedef::Dictionary do
  it "infers types from new subclass calls without a subclass initialize method" do
    source = Solargraph::Source.load_string(%(
      class Sup
        def initialize; end
        def meth; end
      end
      class Sub < Sup
        def meth; end
      end

      Sub.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(9, 10, 9, 10))
    dictionary = described_class.new(api_map, location)
    types = dictionary.infer
    expect(types.map(&:to_s)).to match_array(['Sub'])
  end

  it "follows constant chains" do
    source = Solargraph::Source.load_string(%(
      module Mixin; end
      module Container
        class Foo; end
      end
      Container::Foo::Mixin
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 23, 5, 23))
    dictionary = described_class.new(api_map, location)
    pins = dictionary.define
    expect(pins).to be_empty
  end

  it "rebases inner constants chains" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
        ::Foo::Bar
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(3, 16, 3, 16))
    dictionary = described_class.new(api_map, location)
    pins = dictionary.define
    expect(pins.first.path).to eq('Foo::Bar')
  end
end
