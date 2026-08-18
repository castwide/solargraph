# frozen_string_literal: true

# Contributes a fixed set of pins to every source map, standing in for
# the pins a resolved `require` brings in from a gem or the stdlib.
# Specs assign #pins, register it, and unregister it again afterwards.
class RbsPinConvention < Solargraph::Convention::Base
  class << self
    # @return [Array<Solargraph::Pin::Base>]
    attr_accessor :pins
  end

  self.pins = []

  # @param _source_map [Solargraph::SourceMap]
  # @return [Solargraph::Environ]
  def local _source_map
    Solargraph::Environ.new(pins: self.class.pins)
  end
end

describe Solargraph::Source::Chain::Call do
  it 'recognizes core methods that return subtypes' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      arr = []
      arr.first
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('String')
  end

  it 'recognizes core methods that return self' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      arr = []
      arr.clone
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(2, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('Array')
  end

  it 'handles super calls to same method' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        def my_method
          123
        end
      end
      class Bar < Foo
        def my_method
          456 + super
        end
      end
      Bar.new.my_method))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(11, 14))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('Integer')
  end

  it 'infers return types based on yield call and @yieldreturn' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @yieldreturn [Integer]
        def my_method(&block)
          yield
        end
      end
      Foo.new.my_method))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 14))
    locals = api_map.source_map(nil).locals
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, locals)
    expect(type.tag).to eq('Integer')
  end

  it 'infers return types based only on yield call and @yieldreturn' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @yieldreturn [Integer]
        def my_method(&block)
          yield
        end
      end
      Foo.new.my_method { "foo" }))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 32))
    locals = api_map.source_map(nil).locals
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, locals)
    expect(type.tag).to eq('Integer')
  end

  it 'adds virtual constructors for <Class>.new calls with conflicting return types' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [String]
        def self.new; end
      end
      Foo.new
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('String')
  end

  it 'infers types from macros' do
    pending 'WIP'
    source = Solargraph::Source.load_string(%(
      class Foo
        # @!macro
        #   @return [$1]
        def self.bar; end
      end
      Foo.bar(String)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map(source)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(6, 10))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('String')
  end

  it 'infers generic types from Array#reverse' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      list = array_of_strings
      list.reverse
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Array<String>')
  end

  it 'infers constant return types via returns, ignoring blocks' do
    source = Solargraph::Source.load_string(%(
      def yielder(&blk)
        "foo"
      end

      yielder do
        123
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 8))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.simple_tags).to eq('String')
  end

  it 'infers generic parameterized types through module inclusion' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      module Foo
        # @return [Array<generic<GenericTypeParam>>]
        def baz
        end
      end

      class Baz
        # @return [Baz<String>]
        def self.bar
        end

        include Foo
      end

      Baz.bar.baz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(16, 15))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Array<String>')
  end

  it 'infers generic-class method return values with self reference' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      module Foo
        # @return [Hash<generic<GenericTypeParam>, self>]
        def baz
        end
      end

      class Baz
        # @return [Baz<String>]
        def self.bar
        end

        include Foo
      end

      Baz.bar.baz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(16, 15))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Hash<String, Baz<String>>')
  end

  it 'infers method return types' do
    source = Solargraph::Source.load_string(%(
      def bar
        123
      end

      def baz
        bar
      end

      baz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(9, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.simple_tags).to eq('Integer')
  end

  it 'infers method return types based on method generic' do
    pending('deeper inference support')

    source = Solargraph::Source.load_string(%(
      class Foo
        # @Generic A
        # @param x [generic<A>]
        # @return [generic<A>]
        def bar(x); end
      end

      foo = Foo.new
      a = foo.bar("baz")
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(10, 6))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')
  end

  it 'infers method return types with unused blocks' do
    source = Solargraph::Source.load_string(%(
      def bar
        123
      end

      def baz(&block)
        bar
      end

      baz { "foo" }
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(9, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.simple_tags).to eq('Integer')
  end

  it 'infers generic types from @generic tag' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      class Foo
        # @return [Foo<String>]
        def self.bar
        end

        # @return [Array<generic<GenericTypeParam>>]
        def baz
        end
      end

      Foo.bar.baz
      Foo.bar.baz.first
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(12, 15))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Array<String>')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(13, 20))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')
  end

  it 'infers generic return types from block from yield being a return node' do
    pending('deeper inference support')

    source = Solargraph::Source.load_string(%(
      def yielder(&blk)
        yield
      end

      yielder do
        123
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Integer')
  end

  it 'infers types from union type' do
    source = Solargraph::Source.load_string(%(
      # @type [String, Float]
      list = string_or_float
      list.upcase
      list.ceil
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Integer')
  end

  it 'infers generic types from union type' do
    source = Solargraph::Source.load_string(%(
      # @type [String, Array<Integer>]
      list = string_or_integer
      list.upcase
      list.each
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    # @todo It would be more accurate to return `Enumerator<Array<Integer>>` here
    expect(type.tag).to eq('Enumerator<Integer, String, Array<Integer>>')
  end

  it 'allows calls off of nilable objects by default' do
    source = Solargraph::Source.load_string(%(
      # @type [String, nil]
      f = foo
      a = f.upcase
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 6))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')
  end

  it 'calculates class return type based on class generic' do
    source = Solargraph::Source.load_string(%(
      # @generic A
      class Foo
        # @return [generic<A>]
        def bar; end
      end

      # @type [Foo<String>]
      f = Foo.new
      a = f.bar
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(10, 7))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('String')
  end

  it 'denies calls off of nilable objects when loose union mode is off' do
    source = Solargraph::Source.load_string(%(
      # @type [String, nil]
      f = foo
      a = f.upcase
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new(loose_unions: false)
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 6))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('undefined')
  end

  it 'preserves unions in value position in Hash' do
    source = Solargraph::Source.load_string(%(
      # @param params [Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}]
      def foo(params)
        position = params['position']
        position
        col = position['character']
        col
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new
    api_map.map source

    foo_pin = api_map.source_map('test.rb').pins.find { |p| p.name == 'foo' }
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 8))
    type = chain.infer(api_map, foo_pin, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('::Array, ::Hash{::String => undefined}, ::String, ::Integer, nil')
  end

  it 'preserves undefined and underdefined tyypes in resolution' do
    source = Solargraph::Source.load_string(%(
      # @param params [Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}]
      def foo(params)
        position = params['position']
        position
        col = position['character']
        col
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(6, 8))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('undefined')
  end

  it 'correctly looks up civars' do
    source = Solargraph::Source.load_string(%(
      class Foo
        BAZ = /aaa/

        # @param comment [String]
        def bar(comment)
          b = ("foo" =~ BAZ)
          b
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip = api_map.clip_at('test.rb', [7, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')
  end

  it 'does not mis-parse generic methods with type constraints' do
    source = Solargraph::Source.load_string(%(
      def bl
        out = (Encoding.default_external = 'UTF-8')
        out
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip = api_map.clip_at('test.rb', [3, 8])
    expect(clip.infer.rooted_tags).to eq('::String')
  end

  it 'sends proper gates in ProxyType' do
    source = Solargraph::Source.load_string(%(
      module Foo
        module Bar
          class Symbol
          end
        end
      end

      module Foo
        module Baz
          class Quux
            # @return [void]
            def foo
              s = objects_by_class(Bar::Symbol)
              s
            end

            # @generic T
            # @param klass [Class<generic<T>>]
            # @return [Set<generic<T>>]
            def objects_by_class klass
              # @type [Set<generic<T>>]
              s = Set.new
              s
            end
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip = api_map.clip_at('test.rb', [14, 14])
    expect(clip.infer.rooted_tags).to eq('::Set<::Foo::Bar::Symbol>')
  end

  # Serves an RBS file's pins through the public Convention extension
  # point, standing in for the pins a resolved `require` contributes via
  # DocMap, so these specs exercise calls into a gem/stdlib method.
  shared_context 'with a Box declared in RBS' do
    # create a temporary directory with the scope of the spec
    around do |example|
      require 'tmpdir'
      Dir.mktmpdir('rspec-solargraph-') do |dir|
        @temp_dir = dir
        example.run
      end
    end

    attr_reader :temp_dir

    let(:conversions) do
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
      loader.add(path: Pathname(temp_dir))
      Solargraph::RbsMap::Conversions.new(loader: loader)
    end

    before do
      File.write(File.join(temp_dir, 'box.rbs'), rbs)
      RbsPinConvention.pins = conversions.pins
      Solargraph::Convention.register RbsPinConvention
    end

    after do
      Solargraph::Convention.unregister RbsPinConvention
      RbsPinConvention.pins = []
    end

    # @param code [String]
    # @param position [Array(Integer, Integer)]
    # @return [Solargraph::ComplexType]
    def infer_at code, position
      api_map = Solargraph::ApiMap.new
      source = Solargraph::Source.load_string(code, 'test.rb')
      source_map = Solargraph::SourceMap.map(source)
      api_map.catalog(Solargraph::Bench.new(source_maps: [source_map], live_map: source_map))
      api_map.clip_at('test.rb', position).infer
    end
  end

  context 'with an RBS-declared generic block-form overload accepting a kwrest parameter' do
    include_context 'with a Box declared in RBS'

    let(:rbs) do
      <<~RBS
        class Box
          def self.start: (Integer val, ?String opt1, ?String opt2) -> Box
                         | [T] (Integer val, ?String opt1, ?String opt2, **untyped opts) { (Integer v) -> T } -> T
        end
      RBS
    end

    it 'matches a trailing keyword argument to a kwrest parameter instead of the next positional parameter' do
      type = infer_at(%(
        Box.start(1, "x", foo: true) do |v|
          v
        end
      ), [2, 10])
      expect(type.rooted_tags).to eq('::Integer')
    end

    it 'still resolves the block-form overload when no keyword argument is passed' do
      type = infer_at(%(
        Box.start(1, "x") do |v|
          v
        end
      ), [2, 10])
      expect(type.rooted_tags).to eq('::Integer')
    end
  end

  context 'with overloads that differ only in which keyword(s) they accept' do
    include_context 'with a Box declared in RBS'

    let(:rbs) do
      <<~RBS
        class Box
          def self.add: (path: String) -> Integer
                       | (library: String, ?resolve_dependencies: untyped) -> String
        end
      RBS
    end

    it 'matches a call by the keyword it actually passes, not an earlier overload with an untyped keyword param' do
      code = %(
        Box.add(path: "x")
      )
      type = infer_at(code, [1, code.lines[1].chomp.length])
      expect(type.rooted_tags).to eq('::Integer')
    end
  end
end
