describe Solargraph::Source::Chain do
  it "gets empty definitions for undefined links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.define(nil, nil, [])).to be_empty
  end

  it "infers undefined types for undefined links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.infer(nil, nil, [])).to be_undefined
  end

  it "calls itself undefined if any of its links are undefined" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain).to be_undefined
  end

  it "returns undefined bases for single links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.base).to be_undefined
  end

  it "defines constants from core classes" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String')])
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.first).to be_a(Solargraph::Pin::Namespace)
    expect(pins.first.path).to eq('String')
  end

  it "infers types from core classes" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String')])
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.namespace).to eq('String')
    expect(type.scope).to eq(:class)
  end

  it "infers types from core methods" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String'), Solargraph::Source::Chain::Call.new('new', nil)])
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.namespace).to eq('String')
    expect(type.scope).to eq(:instance)
  end

  it "recognizes literals" do
    chain = described_class.new([Solargraph::Source::Chain::Literal.new('String', nil)])
    expect(chain.literal?).to be(true)
  end

  it "recognizes require parameters" do
    method_call_source = Solargraph::Source.load_string('require "some_file"')
    chain = Solargraph::Source::SourceChainer.chain(method_call_source, Solargraph::Position.new(0, 13))
    expect(chain.links.last).to be_a(Solargraph::Source::Chain::Parameter)
    expect(chain.require_parameter?).to be(true)
  end

  it "recognizes constants" do
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String')])
    expect(chain.constant?).to be(true)
  end

  it "recognizes unfinished constants" do
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String'), Solargraph::Source::Chain::Constant.new('<undefined>')])
    expect(chain.constant?).to be(true)
    expect(chain.base.constant?).to be(true)
    expect(chain.undefined?).to be(true)
    expect(chain.base.undefined?).to be(false)
  end

  it "infers types from new subclass calls without a subclass initialize method" do
    code = %(
      class Sup
        def initialize; end
        def meth; end
      end
      class Sub < Sup
        def meth; end
      end
    )
    map = Solargraph::SourceMap.load_string(code)
    api_map = Solargraph::ApiMap.new
    api_map.index map.pins
    sig = Solargraph::Source.load_string('Sub.new')
    chain = Solargraph::Source::SourceChainer.chain(sig, Solargraph::Position.new(0, 5))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.name).to eq('Sub')
  end

  it 'infers types from factory methods' do
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: [
            Solargraph::Pin::FactoryParameter.new(
              method_name: 'create',
              method_namespace: 'FactoryBot',
              method_scope: :class,
              param_name: 'klass',
              value: :my_model,
              return_type: Solargraph::ComplexType.parse('MyModel')
            )
          ]
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    source = Solargraph::Source.new(%(
      class MyModel
      end
      module FactoryBot
        def self.create(klass, **args)
        end
      end

      FactoryBot.create(:my_model, name: 'test')
    ), 'test.rb')
    source_map = Solargraph::SourceMap.map(source)

    api_map = Solargraph::ApiMap.new
    api_map.index source_map.pins + source_map.convention_pins
    chain = Solargraph::Source::SourceChainer.chain(source_map.source, Solargraph::Position.new(8, 20))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.name).to eq('MyModel')
    Solargraph::Convention.unregister dummy_convention
  end

  it "defines factory parameters" do
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: [
            Solargraph::Pin::FactoryParameter.new(
              method_name: 'create',
              method_namespace: 'FactoryBot',
              method_scope: :class,
              param_name: 'klass',
              value: :my_model,
              return_type: Solargraph::ComplexType.parse('MyModel'),
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 6, 0, 18)) # eg. class MyModel
            )
          ]
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    source = Solargraph::Source.new(%(
      class MyModel
      end
      module FactoryBot
        def self.create(klass, **args)
        end
      end

      FactoryBot.create(:my_model, name: 'test')
    ), 'test.rb')
    source_map = Solargraph::SourceMap.map(source)

    api_map = Solargraph::ApiMap.new
    api_map.index source_map.pins + source_map.convention_pins
    chain = Solargraph::Source::SourceChainer.chain(source_map.source, Solargraph::Position.new(8, 30))
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.length).to eq(1)
    expect(pins.first).to be_a(Solargraph::Pin::FactoryParameter)
    Solargraph::Convention.unregister dummy_convention
  end

  it 'defines factory parameters passed through a splat' do
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: %i[published pinned].map do |trait|
            Solargraph::Pin::FactoryParameter.new(
              method_name: 'create',
              method_namespace: 'FactoryBot',
              method_scope: :class,
              param_name: 'traits',
              value: trait,
              decl: :restarg,
              return_type: nil,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 6, 0, 18))
            )
          end
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    source = Solargraph::Source.new(%(
      module FactoryBot
        def self.create(name, *traits, **overrides)
        end
      end

      FactoryBot.create(:post, :published, :pinned)
    ), 'test.rb')
    source_map = Solargraph::SourceMap.map(source)

    api_map = Solargraph::ApiMap.new
    api_map.index source_map.pins + source_map.convention_pins
    chain = Solargraph::Source::SourceChainer.chain(source_map.source, Solargraph::Position.new(6, 46))
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.map(&:value)).to eq([:pinned])
    Solargraph::Convention.unregister dummy_convention
  end

  it 'defines factory parameters when no signature matches the arguments' do
    # The pins below stand for:
    #
    #   module Routes
    #     # @param controller [Integer] e.g. an RBS type alias the literal does not conform to
    #     # @return [void]
    #     def self.controller(controller); end
    #   end
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        namespace = Solargraph::Pin::Namespace.new(name: 'Routes', type: :module)
        method = Solargraph::Pin::Method.new(name: 'controller', closure: namespace, scope: :class)
        signature = Solargraph::Pin::Signature.new(closure: method, parameters: [],
                                                   return_type: Solargraph::ComplexType::VOID)
        signature.parameters << Solargraph::Pin::Parameter.new(name: 'controller', closure: signature,
                                                               return_type: Solargraph::ComplexType.parse('Integer'))
        method.signatures = [signature]
        Solargraph::Environ.new(
          pins: [
            namespace,
            method,
            Solargraph::Pin::FactoryParameter.new(
              method_name: 'controller',
              method_namespace: 'Routes',
              method_scope: :class,
              param_name: 'controller',
              value: :posts,
              return_type: nil,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 6, 0, 18))
            )
          ]
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    source = Solargraph::Source.new(%(
      Routes.controller(:posts)
    ), 'test.rb')
    source_map = Solargraph::SourceMap.map(source)

    api_map = Solargraph::ApiMap.new
    api_map.index source_map.pins + source_map.convention_pins
    chain = Solargraph::Source::SourceChainer.chain(source_map.source, Solargraph::Position.new(1, 26))
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins.map(&:value)).to eq([:posts])
    Solargraph::Convention.unregister dummy_convention
  end

  it 'defines factory parameters only of the signature that matches the arguments' do
    # The pins below stand for:
    #
    #   module Routes
    #     # @overload find(kind, extra)
    #     #   @param kind [Symbol]
    #     #   @param extra [Symbol]
    #     #   @return [void]
    #     # @overload find(id, name)
    #     #   @param id [Integer]
    #     #   @param name [Symbol]
    #     #   @return [void]
    #     def self.find(*args); end
    #   end
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        namespace = Solargraph::Pin::Namespace.new(name: 'Routes', type: :module)
        method = Solargraph::Pin::Method.new(name: 'find', closure: namespace, scope: :class)
        method.signatures = [%w[Symbol kind Symbol extra], %w[Integer id Symbol name]].map do |type1, name1, type2, name2|
          signature = Solargraph::Pin::Signature.new(closure: method, parameters: [],
                                                     return_type: Solargraph::ComplexType::VOID)
          [[type1, name1], [type2, name2]].each do |type, name|
            signature.parameters << Solargraph::Pin::Parameter.new(name: name, closure: signature,
                                                                   return_type: Solargraph::ComplexType.parse(type))
          end
          signature
        end
        Solargraph::Environ.new(
          pins: [
            namespace,
            method,
            Solargraph::Pin::FactoryParameter.new(
              method_name: 'find',
              method_namespace: 'Routes',
              method_scope: :class,
              param_name: 'name',
              value: :admin,
              return_type: nil,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 6, 0, 18))
            )
          ]
        )
      end
    end

    Solargraph::Convention.register dummy_convention

    source = Solargraph::Source.new(%(
      Routes.find(:posts, :admin)
    ), 'test.rb')
    source_map = Solargraph::SourceMap.map(source)

    api_map = Solargraph::ApiMap.new
    api_map.index source_map.pins + source_map.convention_pins
    chain = Solargraph::Source::SourceChainer.chain(source_map.source, Solargraph::Position.new(1, 28))
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins).to be_empty
    Solargraph::Convention.unregister dummy_convention
  end

  context 'with factory parameters passed as keywords' do
    # @param call [String] a call to Routes.get
    # @param column [Integer] where the literal is in the call
    # @param param_name [String]
    # @param parameters [String] the parameters of Routes.get
    # @return [Array<Solargraph::Pin::Base>]
    def define_literal call, column, param_name, parameters: 'path = nil, to: nil, **mapping'
      factory_parameter = Solargraph::Pin::FactoryParameter.new(
        method_name: 'get',
        method_namespace: 'Routes',
        method_scope: :class,
        param_name: param_name,
        value: 'posts#show',
        return_type: nil,
        location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 6, 0, 18))
      )
      source = Solargraph::Source.load_string(%(module Routes
  def self.get(#{parameters}); end
end
#{call}
), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.index Solargraph::SourceMap.map(source).pins + [factory_parameter]
      chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, column))
      chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    end

    it 'defines a literal passed to a keyword parameter' do
      pins = define_literal("Routes.get('latest', to: 'posts#show')", 27, 'to')
      expect(pins.map(&:value)).to eq(['posts#show'])
    end

    it 'defines a literal passed to a keyword rest parameter' do
      pins = define_literal("Routes.get('latest' => 'posts#show')", 25, 'mapping')
      expect(pins.map(&:value)).to eq(['posts#show'])
    end

    it 'does not pass a named keyword to the keyword rest parameter' do
      pins = define_literal("Routes.get('latest', to: 'posts#show')", 27, 'mapping')
      expect(pins).to be_empty
    end

    it 'defines a literal in a hash passed to a positional parameter' do
      pins = define_literal("Routes.get('latest' => 'posts#show')", 25, 'options', parameters: 'options')
      expect(pins.map(&:value)).to eq(['posts#show'])
    end

    it 'does not pass a keyword to a positional parameter' do
      pins = define_literal("Routes.get(to: 'posts#show')", 17, 'path')
      expect(pins).to be_empty
    end
  end

  it "follows constant chains" do
    source = Solargraph::Source.load_string(%(
      module Mixin; end
      module Container
        class Foo; end
      end
      Container::Foo::Mixin
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(5, 23))
    pins = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins).to be_empty
  end

  it "rebases inner constants chains" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
        ::Foo::Bar
      end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 16))
    pins = chain.define(api_map, Solargraph::Pin::ProxyType.new(closure: Solargraph::Pin::Namespace.new(name: 'Foo'), return_type: Solargraph::ComplexType.parse('Class<Foo>')), [])
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
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(6, 16))
    pins = chain.define(api_map, Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.parse('Class<Foo::Other>')), [])
    expect(pins.first.path).to eq('Foo::Bar::Baz')
  end

  it "avoids recursive variable assignments" do
    source = Solargraph::Source.load_string(%(
      @foo = @bar
      @bar = @foo.quz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(2, 18))
    expect {
      chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    }.not_to raise_error
  end

  it "pulls types from multiple lines of code" do
    source = Solargraph::Source.load_string(%(
      123
      'abc'
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(2, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('String')
  end

  it "uses last line of a begin expression as return type" do
    source = Solargraph::Source.load_string(%(
      begin
        123
        'abc'
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('String')
  end

  it "matches constants on complete symbols" do
    source = Solargraph::Source.load_string(%(
      class Correct; end
      class NotCorrect; end
      Correct
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 6))
    result = chain.define(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(result.map(&:path)).to eq(['Correct'])
  end

  it 'infers booleans from or-nodes passed to !' do
    source = Solargraph::Source.load_string(%(
      !([].include?('.') || [].include?('#'))
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Parser.chain(source.node, source.filename)
    type = chain.infer(api_map, api_map.pins.first, [])
    expect(type.tag).to eq('Boolean')
  end

  it 'infers last type from and-nodes' do
    source = Solargraph::Source.load_string(%(
      [] && ''
    ))
    api_map = Solargraph::ApiMap.new
    chain = Solargraph::Parser.chain(source.node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('String')
  end

  it 'infers multiple types from or-nodes' do
    source = Solargraph::Source.load_string(%(
      [] || ''
    ))
    api_map = Solargraph::ApiMap.new
    chain = Solargraph::Parser.chain(source.node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('Array, String')
  end

  it 'infers Procs from block-pass nodes' do
    source = Solargraph::Source.load_string(%(
      x = []
      x.map(&:foo)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    node = source.node_at(2, 12)
    chain = Solargraph::Parser.chain(node, 'test.rb')
    pin = chain.define(api_map, Solargraph::Pin::ROOT_PIN, []).first
    expect(pin.return_type.tag).to eq('Proc')
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('Proc')
  end

  it 'infers Boolean from true' do
    source = Solargraph::Source.load_string(%(
      @x = true
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    node = source.node_at(1, 6)
    # chain = Solargraph::Source::NodeChainer.chain(node, 'test.rb')
    chain = Solargraph::Parser.chain(node, 'test.rb')
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('Boolean')
  end

  it 'infers self from Object#freeze' do
    source = Solargraph::Source.load_string(%(
      Array.new.freeze
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    node = source.node_at(1, 16)
    chain = Solargraph::Parser.chain(node, 'test.rb')
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('Array')
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
    api_map = Solargraph::ApiMap.new
    api_map.map source
    closure = api_map.get_path_pins('Outer::Inner').first

    outer_node = api_map.get_path_pins('Outer::Inner.outer_string').first.send(:method_body_node)
    outer_chain = Solargraph::Parser.chain(outer_node)
    outer_type = outer_chain.infer(api_map, closure, [])
    expect(outer_type.tag).to eq('Class<Outer::String>')
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
    api_map = Solargraph::ApiMap.new
    api_map.map source
    closure = api_map.get_path_pins('Outer::Inner').first

    core_node = api_map.get_path_pins('Outer::Inner.core_string').first.send(:method_body_node)
    core_chain = Solargraph::Parser.chain(core_node)
    core_type = core_chain.infer(api_map, closure, [])
    expect(core_type.tag).to eq('Class<String>')
  end

  it 'infers String from interpolated strings' do
    source = Solargraph::Source.load_string('"#{Object}"', 'test.rb')
    node = source.node
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Parser.chain(node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('String')
  end

  it 'infers Symbol from symbols' do
    source = Solargraph::Source.load_string(':foo', 'test.rb')
    node = source.node
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Parser.chain(node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('Symbol')
  end

  it 'infers Symbol from quoted symbols' do
    source = Solargraph::Source.load_string(':"foo"', 'test.rb')
    node = source.node
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Parser.chain(node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.simple_tags).to eq('Symbol')
  end

  it 'infers Symbol from interpolated symbols' do
    source = Solargraph::Source.load_string(':"#{Object}"', 'test.rb')
    node = source.node
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Parser.chain(node)
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('Symbol')
  end

  it 'infers namespaces from constant aliases' do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
      end
      Alias = Foo
      Alias::Bar.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    node = source.node_at(5, 17)
    chain = Solargraph::Parser.chain(node, 'test.rb')
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('Foo::Bar')
  end

  it 'detects blocks in multiple calls' do
    source = Solargraph::Source.load_string(%(
      foo { |x| x }.bar { |y| y }
    ))
    chain = Solargraph::Parser.chain(source.node)
    expect(chain.links.length).to eq(2)
    expect(chain.links[0]).to be_with_block
    expect(chain.links[1]).to be_with_block
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
  end

  it 'recognizes nil safe navigation' do
    source = Solargraph::Source.load_string(%(
      String.new&.strip
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 18))
    tag = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(tag.to_s).to eq('String, nil')
  end

  it 'infers Class<self> from Object#class' do
    source = Solargraph::Source.load_string(%(
      String.new.class
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 17))
    tag = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(tag.to_s).to eq('Class<String>')
  end

  it 'gracefully handles requests for type of generic method in chain' do
    source = Solargraph::Source.load_string(%(
      # @generic T
      # @param x [generic<T>]
      # @return [generic<T>]}
      def foo(x); x; end
      foo('string')
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(5, 7))
    expect { chain.infer(api_map, Solargraph::Pin::ROOT_PIN, []) }.not_to raise_error
    # @todo get this to also return a defined type
    # type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    # expect(type.to_s).to eq('String')
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
    obj_fn_pin = api_map.get_path_pins('Example.obj').first
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(12, 6))
    type = chain.infer(api_map, obj_fn_pin, api_map.source_map('test.rb').locals)
    expect(type.to_s).to eq('String')
  end
end
