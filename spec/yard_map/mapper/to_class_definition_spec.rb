# frozen_string_literal: true

describe Solargraph::YardMap::Mapper::ToClassDefinition do
  around do |example|
    YARD::Registry.clear
    example.run
    YARD::Registry.clear
  end

  # Maps a source string the way a gem's yardoc would arrive: YARD parses it,
  # and the Mapper converts the resulting code objects into pins.
  #
  # @param code [String]
  # @return [Array<Solargraph::Pin::Base>]
  def map code
    YARD.parse_string(code)
    Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
  end

  # @param pins [Array<Solargraph::Pin::Base>]
  # @param path [String]
  # @return [Array<Solargraph::Pin::Base>]
  def pins_at pins, path
    pins.select { |pin| pin.path == path }
  end

  it 'indexes the class defined by a Class.new block' do
    pins = map(<<~RUBY)
      Foo = Class.new(StandardError) do
        def bar; end
      end
    RUBY
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Namespace])
    expect(pins_at(pins, 'Foo#bar').map(&:class)).to eq([Solargraph::Pin::Method])
  end

  it 'emits a superclass reference instead of a constant pin' do
    pins = map(<<~RUBY)
      Foo = Class.new(StandardError) do
        def bar; end
      end
    RUBY
    expect(pins).not_to include(an_instance_of(Solargraph::Pin::Constant))
    superclass = pins.grep(Solargraph::Pin::Reference::Superclass).first
    expect(superclass.name).to eq('StandardError')
    expect(superclass.closure.path).to eq('Foo')
  end

  it 'keeps YARD tags written inside the block' do
    pins = map(<<~RUBY)
      Foo = Class.new(StandardError) do
        # @return [Integer]
        def bar; end
      end
    RUBY
    expect(pins_at(pins, 'Foo#bar').first.return_type.to_s).to eq('Integer')
  end

  it 'gives the class the documentation written on the constant' do
    pins = map(<<~RUBY)
      # An erroneous condition.
      Foo = Class.new(StandardError)
    RUBY
    expect(pins_at(pins, 'Foo').first.comments).to include('An erroneous condition.')
  end

  it 'resolves a superclass named relative to the enclosing namespace' do
    pins = map(<<~RUBY)
      module Errors
        class Base < StandardError; end
        Specific = Class.new(Base)
      end
    RUBY
    api_map = Solargraph::ApiMap.new(pins: pins)
    expect(api_map.super_and_sub?('Errors::Base', 'Errors::Specific')).to be(true)
    expect(api_map.super_and_sub?('StandardError', 'Errors::Specific')).to be(true)
  end

  it 'finds methods from the block through the api map' do
    pins = map(<<~RUBY)
      module Errors
        Specific = Class.new(StandardError) do
          attr_accessor :retry_after_seconds
        end
      end
    RUBY
    api_map = Solargraph::ApiMap.new(pins: pins)
    stack = api_map.get_method_stack('Errors::Specific', 'retry_after_seconds')
    expect(stack.map(&:path)).to eq(['Errors::Specific#retry_after_seconds'])
  end

  it 'handles Class.new with a superclass and no block' do
    pins = map('Foo = Class.new(StandardError)')
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Namespace])
    expect(pins.grep(Solargraph::Pin::Reference::Superclass).map(&:name)).to eq(['StandardError'])
  end

  it 'handles Class.new with no superclass and no block' do
    pins = map('Foo = Class.new')
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Namespace])
    expect(pins.grep(Solargraph::Pin::Reference::Superclass)).to be_empty
  end

  it 'handles Class.new with no superclass and a block' do
    pins = map(<<~RUBY)
      Foo = Class.new do
        def bar; end
      end
    RUBY
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Namespace])
    expect(pins_at(pins, 'Foo#bar')).not_to be_empty
  end

  it 'leaves a conditional Class.new as a constant' do
    pins = map('Foo = (Class.new(StandardError) if RUBY_VERSION)')
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Constant])
  end

  it 'leaves Class.new used as an ordinary value as a constant' do
    pins = map('Foo = Class.new(StandardError).new')
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Constant])
  end

  it 'leaves an unrelated constant alone' do
    pins = map("Foo = 'a string'")
    expect(pins_at(pins, 'Foo').map(&:class)).to eq([Solargraph::Pin::Constant])
  end

  it 'logs and returns nil when reparsing raises' do
    code_object = YARD::CodeObjects::ConstantObject.new(YARD::Registry.root, :Foo) do |obj|
      obj.value = 'Class.new(StandardError)'
    end
    allow(described_class).to receive(:definition_pins).and_raise(StandardError, 'boom')
    allow(Solargraph.logger).to receive(:info)
    expect(described_class.make(code_object)).to be_nil
    expect(Solargraph.logger).to have_received(:info)
      .with(/Could not reparse Foo as a class definition: \[StandardError\] boom/)
  end

  it 'keeps a reference whose closure is two levels below the constant path' do
    pins = map(<<~RUBY)
      Foo = Class.new(StandardError) do
        module Nested
          include Comparable
        end
      end
    RUBY
    reference = pins.grep(Solargraph::Pin::Reference::Include).find { |pin| pin.name == 'Comparable' }
    expect(reference).not_to be_nil
    expect(reference.closure.path).to eq('Foo::Nested')
  end

  it 'falls back to a constant pin when the value cannot be parsed' do
    code_object = YARD::CodeObjects::ConstantObject.new(YARD::Registry.root, :Foo) do |obj|
      obj.value = 'Class.new(StandardError) do'
    end
    pins = Solargraph::YardMap::Mapper.new([code_object]).map
    expect(pins.map(&:class)).to eq([Solargraph::Pin::Constant])
    expect(pins.first.name).to eq('Foo')
  end

  it 'emits no parser nodes' do
    pins = map(<<~RUBY)
      module Errors
        Specific = Class.new(StandardError) do
          attr_accessor :retry_after_seconds

          def initialize(retry_after_seconds)
            @retry_after_seconds = retry_after_seconds
          end
        end
      end
    RUBY
    expect(nodes_reachable_from(pins)).to be_empty
  end

  it 'gives every emitted pin the location of the constant' do
    pins = map(<<~RUBY)
      Foo = Class.new(StandardError) do
        def bar; end
      end
    RUBY
    expected = Solargraph::YardMap::Mapper::ToConstant.make(YARD::Registry.at('Foo')).location
    expect(pins.map(&:location).compact.uniq).to eq([expected])
  end

  # A codebase that documented one of these constants by hand keeps its
  # `@!parse` stub in the workspace pinset while the gem now contributes real
  # pins at the same path. Catalog order is core, gem, conventions, workspace,
  # so the gem's pins come first.
  #
  # @param gem_pins [Array<Solargraph::Pin::Base>]
  # @param workspace_code [String]
  # @return [Solargraph::ApiMap]
  def api_map_with gem_pins, workspace_code
    workspace = Solargraph::SourceMap.map(Solargraph::Source.load_string(workspace_code, 'stub.rb'))
    api_map = Solargraph::ApiMap.new
    core = Solargraph::ApiMap.class_variable_get(:@@core_map).pins
    api_map.send(:store).update(core, gem_pins, [], workspace.pins, [])
    api_map.send(:cache).clear
    api_map
  end

  context 'with a hand-written @!parse stub at the same path' do
    let(:gem_pins) do
      map(<<~RUBY)
        module Errors
          Specific = Class.new(StandardError) do
            attr_accessor :retry_after_seconds
          end
        end
      RUBY
    end

    let(:stub) do
      <<~RUBY
        # @!parse
        #   module Errors
        #     class Specific < ::StandardError
        #       # @return [Integer]
        #       attr_accessor :retry_after_seconds
        #     end
        #   end
      RUBY
    end

    it 'resolves the method with the stub present' do
      api_map = api_map_with(gem_pins, stub)
      stack = api_map.get_method_stack('Errors::Specific', 'retry_after_seconds')
      expect(stack).not_to be_empty
      expect(stack.map(&:path)).to all(eq('Errors::Specific#retry_after_seconds'))
    end

    it 'keeps the superclass chain intact' do
      api_map = api_map_with(gem_pins, stub)
      expect(api_map.super_and_sub?('StandardError', 'Errors::Specific')).to be(true)
    end

    it 'holds two namespace pins and no constant pin at the path' do
      api_map = api_map_with(gem_pins, stub)
      expect(api_map.get_path_pins('Errors::Specific').map(&:class))
        .to eq([Solargraph::Pin::Namespace, Solargraph::Pin::Namespace])
    end

    # How far the stub's tag gets depends on the base. Where
    # ApiMap::Store#combine_duplicate_method_pins exists, the two pins merge
    # into one typed pin and the tag reaches the call site. Where it does not,
    # the stack keeps both, the gem's untyped pin sorts first, and
    # Source::Chain::Call#resolve infers from `stack.first` -- so the tag is
    # shadowed and inference is undefined. Either way the stub is redundant:
    # the call resolves without it.
    it 'keeps the stub return tag in the method stack' do
      api_map = api_map_with(gem_pins, stub)
      stack = api_map.get_method_stack('Errors::Specific', 'retry_after_seconds')
      expect(stack.map { |pin| pin.return_type.to_s }).to include('Integer')
    end

    it 'lets an @!override on the method path type the gem pin' do
      api_map = api_map_with(gem_pins, <<~RUBY)
        # @!override Errors::Specific#retry_after_seconds
        #   @return [Integer]
      RUBY
      stack = api_map.get_method_stack('Errors::Specific', 'retry_after_seconds')
      expect(stack.map { |pin| pin.return_type.to_s }).to eq(['Integer'])
    end
  end

  # Nodes hold a reference to the buffer they were parsed from, which both
  # bloats the marshalled gem cache and makes inference reach for a source map
  # that does not exist.
  #
  # @param object [Object]
  # @param seen [Set]
  # @return [Array<String>]
  def nodes_reachable_from object, seen = Set.new
    return [] unless seen.add?(object.object_id)

    case object
    when Parser::AST::Node, Parser::Source::Buffer, Parser::Source::Map, YARD::Docstring
      [object.class.to_s]
    when Array
      object.flat_map { |item| nodes_reachable_from(item, seen) }
    when Hash
      object.each_value.flat_map { |value| nodes_reachable_from(value, seen) }
    when String, Symbol, Numeric, nil, true, false
      []
    else
      object.instance_variables.flat_map do |ivar|
        nodes_reachable_from(object.instance_variable_get(ivar), seen)
      end
    end
  end
end
