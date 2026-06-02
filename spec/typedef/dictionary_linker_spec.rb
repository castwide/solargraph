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
    dictionary = described_class.new(api_map, 'test.rb', [9, 10])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Sub')
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
    dictionary = described_class.new(api_map, 'test.rb', [5, 23])
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
    dictionary = described_class.new(api_map, 'test.rb', [3, 16])
    pins = dictionary.define
    expect(pins.first.path).to eq('Foo::Bar')
  end

  it "resolves relative constant paths" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar
          class Baz; end
        end
        module Other
          Bar::Baz
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 16])
    pins = dictionary.define
    expect(pins.first.path).to eq('Foo::Bar::Baz')
  end

  it "avoids recursive variable assignments" do
    source = Solargraph::Source.load_string(%(
      @foo = @bar
      @bar = @foo.quz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [2, 18])
    expect {
      dictionary.define
    }.not_to raise_error
  end

  it "pulls types from multiple lines of code" do
    source = Solargraph::Source.load_string(%(
      123
      'abc'
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [2, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it "uses last line of a begin expression as return type" do
    source = Solargraph::Source.load_string(%(
      begin
        123
        'abc'
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 9])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it "matches constants on complete symbols" do
    source = Solargraph::Source.load_string(%(
      class Correct; end
      class NotCorrect; end
      Correct
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 6])
    result = dictionary.define
    expect(result.map(&:path)).to eq(['Correct'])
  end

  it 'infers booleans from or-nodes passed to !' do
    source = Solargraph::Source.load_string(%(
      !([].include?('.') || [].include?('#'))
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 7])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Boolean')
  end

  it 'infers last type from and-nodes' do
    source = Solargraph::Source.load_string(%(
      [] && ''
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 14])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'infers multiple types from or-nodes' do
    source = Solargraph::Source.load_string(%(
      [] || ''
    ), 'test.rb')
    # api_map = Solargraph::ApiMap.new
    # chain = Solargraph::Parser.chain(source.node)
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 10])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array | String')
  end

  it 'infers Procs from block-pass nodes' do
    pending 'Not sure what position to define/infer'
    source = Solargraph::Source.load_string(%(
      x = []
      x.map(&:foo)
    ), 'test.rb')
    # api_map = Solargraph::ApiMap.new
    # api_map.map source
    # node = source.node_at(2, 12)
    # chain = Solargraph::Parser.chain(node, 'test.rb')
    # pin = chain.define(api_map, Solargraph::Pin::ROOT_PIN, []).first
    # expect(pin.return_type.tag).to eq('Proc')
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    # expect(type.tag).to eq('Proc')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [0, 0])
    pins = dictionary.define
    expect(pins.map(&:return_type).map(&:tag)).to eq(['Proc'])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Proc')
  end

  it 'infers Boolean from true' do
    source = Solargraph::Source.load_string(%(
      @x = true
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 8])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Boolean')
  end

  it 'infers self from Array#new' do
    source = Solargraph::Source.load_string(%(
      Array.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 12])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array')
  end

  it 'infers self from inherited Object#freeze' do
    source = Solargraph::Source.load_string(%(
      Array.new.freeze
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 16])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Array')
  end

  it 'infers the nearest constants first' do
    source = Solargraph::Source.load_string(%(
      module Outer
        class String; end
      end
      module Outer
        module Inner
          def self.outer_string
            String
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 19])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Class[Outer::String]')
  end

  it 'infers rooted constants' do
    source = Solargraph::Source.load_string(%(
      module Outer
        class String; end
      end
      module Outer
        module Inner
          def self.core_string
            ::String
          end
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [6, 19])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Class[String]')
  end

  it 'infers String from interpolated strings' do
    source = Solargraph::Source.load_string('"#{Object}"', 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [0, 0])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'infers Symbol from symbols' do
    source = Solargraph::Source.load_string(':foo', 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [0, 0])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Symbol')
  end

  it 'infers Symbol from quoted symbols' do
    source = Solargraph::Source.load_string(':"foo"', 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [0, 0])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Symbol')
  end

  it 'infers Symbol from interpolated symbols' do
    source = Solargraph::Source.load_string(':"#{Object}"', 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [0, 0])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Symbol')
  end

  it 'infers namespaces from constant aliases' do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
      end
      Alias = Foo
      Alias::Bar.new
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [5, 17])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Foo::Bar')
  end

  it 'infers instance variables from sequential assignments' do
    pending('sequential assignment support')

    source = Solargraph::Source.load_string(%(
      def foo
        @foo = nil
        @foo = 'foo'
      end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('#foo').first
    type = pin.probe(api_map)
    expect(type.simple_tags).to eq('String')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [3, 8])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'recognizes nil safe navigation without upstream nil' do
    source = Solargraph::Source.load_string(%(
      String.new&.strip
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 18])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'recognizes nil safe navigation with upstream nil' do
    source = Solargraph::Source.load_string(%(
      # @return [String, nil]
      def foo; end
      foo&.upcase
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [2, 11])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String | nil')
  end

  it 'infers Class<self> from Object#class' do
    source = Solargraph::Source.load_string(%(
      String.new.class
    ), 'test.rb')
    # api_map = Solargraph::ApiMap.new.map(source)
    # chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 17))
    # tag = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    # expect(tag.to_s).to eq('Class<String>')
    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [1, 17])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('Class[String] | Class')
  end

  it 'resolves variable and method name collisions' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @return [String]
        def stringify; end

        class << self
          # @return [Example]
          def obj(foo); end
        end
      end

      obj = Example.obj
      str = obj.stringify
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [12, 7])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'infers class variables' do
    source = Solargraph::Source.load_string(%(
      class Example
        @@foo = 'string'

        def bar
          @@foo
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    dictionary = described_class.new(api_map, 'test.rb', [4, 12])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String')
  end

  it 'understands &. in chains' do
    source = Solargraph::Source.load_string(%(
      # @param a [String, nil]
      # @return [String, nil]
      def foo a
        b = a&.upcase
        b
      end

      b = foo 123
      b
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    dictionary = described_class.new(api_map, 'test.rb', [5, 8])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String | nil')

    dictionary = described_class.new(api_map, 'test.rb', [9, 6])
    typeset = dictionary.infer
    expect(typeset.to_s).to eq('String | nil')
  end
end
