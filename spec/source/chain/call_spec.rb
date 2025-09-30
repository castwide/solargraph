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
        def self.new; end
      end
      Foo.new
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    # @todo This test looks invalid now. If `Foo.new` is an empty method,
    #   shouldn't it return `nil` or `undefined`?
    # expect(type.tag).to eq('Foo')
  end

  it 'infers types from macros' do
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

  it 'infers generic types' do
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

  it 'infers generic parameterized types through module inclusion via RBS definition of module' do
    source = Solargraph::Source.load_string(%(
      foo = ['bar'].to_set

      foo
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Set<String>')
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

  it 'infers generic-class method return values with self reference through RBS definition' do
    source = Solargraph::Source.load_string(%(
      a = ['bar']
      # @param item [String]
      foo = a.to_set.classify do |item|
       item.class
      end

      foo
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 12))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Array<String>')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 20))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Set<String>')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 17))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Class<String>')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(7, 9))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Hash{Class<String> => Set<String>}')
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

  xit 'infers method return types based on method generic' do
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

  it 'infers generic types' do
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

  xit 'infers generic return types from block from yield being a return node' do
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

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 8))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('::Array, ::Hash{::String => undefined}, ::String, ::Integer')
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

  it 'does not infer undefined types when declared ones exist' do
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def other; end
      def foo
        parts = [''] + other
        parts
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(5, 8))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('::Array<::String>')
  end

  it 'understands types in an Array#+ scenario' do
    source = Solargraph::Source.load_string(%(
      module A
        class B
          def c
            ([B.new] + [B.new]).each do |d|
              d
            end
          end
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(5, 14))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tags).to eq('A::B')
  end

  it 'qualifies types in an Array#+ scenario' do
    source = Solargraph::Source.load_string(%(
      module A
        class B
          def c
            ([B.new] + [B.new]).each do |d|
              d
            end
          end
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(5, 14))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('::A::B')
  end

  it 'handles subclass and superclass issues in Array#+' do
    source = Solargraph::Source.load_string(%(
      module A
        class B; end
        class C < B
          def c
            ([B.new] + [C.new]).each do |d|
              d
            end
          end
          def d
            ([C.new] + [B.new]).each do |d|
              d
            end
          end
       end
     end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(6, 14))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.rooted_tags).to eq('::A::B').or eq('::A::B, ::A::C').or eq('::A::C, ::A::B')

    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(11, 14))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    # valid options here:
    #   * emit type checker warning when adding [B.new] and type whole thing as '::A::B'
    #   * type whole thing as '::A::B, A::C'
    #   * type as undefined
    expect(type.rooted_tags).to eq('::A::B, ::A::C').or eq('::A::C, ::A::B').or be_undefined
    expect(type.rooted_tags).not_to eq('::A::C')
  end

  it 'qualifies types in a second Array#+' do
    source = Solargraph::Source.load_string(%(
      module A1
        class B1
          # @return [Array<A::D::E>]
          def foo; end
        end
      end
      module A
        module D
          class E; end
        end
        class B; end
        class C < B
          def e
            ([D::E.new] + [D::E.new]).each do |d|
              d
            end
          end
          def f
            de1 = [D::E.new]
            de2 = [D::E.new]
            (de1 + de2).each do |d|
              d
            end
          end
          # @return [Array<D::E>]
          attr_reader :g
          # @return [Array<D::E>]
          attr_reader :h
          def i
            de1 = [D::E.new]
            (g + de1).each do |d|
              d
            end
          end
          def j
            (g + h).each do |d|
              d
            end
          end
          def k
            arr1 = A1::B1.new.foo + h
            arr1
            arr1.each do |d1|
              d1
            end
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip = api_map.clip_at('test.rb', [15, 14])
    expect(clip.infer.rooted_tags).to eq('::A::D::E')

    clip = api_map.clip_at('test.rb', [22, 14])
    expect(clip.infer.rooted_tags).to eq('::A::D::E')

    clip = api_map.clip_at('test.rb', [32, 14])
    expect(clip.infer.rooted_tags).to eq('::A::D::E')

    clip = api_map.clip_at('test.rb', [37, 14])
    expect(clip.infer.rooted_tags).to eq('::A::D::E')

    clip = api_map.clip_at('test.rb', [42, 12])
    expect(clip.infer.rooted_tags).to eq('::Array<::A::D::E>')
  end

  xit 'correctly looks up civars' do
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
end
