describe Solargraph::Pin::Parameter do
  it 'detects block parameter return types from @yieldparam tags' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @yieldparam [Array]
      def yielder; end
      yielder do |things|
        things
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(4, 9))
    expect(clip.infer.tag).to eq('Array')
  end

  it 'infers @yieldparam tags with skipped arguments' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @yieldparam [String]
      # @yieldparam [Integer]
      def yielder; end
      yielder do |things|
        things
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(5, 9))
    expect(clip.infer.tag).to eq('String')
  end

  it 'infers generic types' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      class Foo
        # @return [Foo<String>]
        def self.bar
        end

        # @yieldparam [generic<GenericTypeParam>]
        def baz
        end
      end

      Foo.bar.baz do |yielded_parameter|
        yielded_parameter.down
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(13, 10))
    expect(clip.infer.tag).to eq('String')
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(13, 27))
    pins = clip.complete.pins
    expect(pins.map(&:path)).to include('String#downcase')
  end

  it 'gracefully handles missing generic parameters' do
    source = Solargraph::Source.load_string(%(
      # @generic GenericTypeParam
      class Foo
        # @return [Foo<String>]
        def self.bar
        end

        # @yieldparam [generic]
        def baz
        end
      end

      Foo.bar.baz do |yielded_parameter|
        yielded_parameter.down
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(13, 10))
    expect(clip.infer.tag).to eq('generic')
  end

  it 'detects block parameter return types from core methods' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      String.new.split.each do |str|
        str
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(2, 8))
    expect(clip.infer.tag).to eq('String')
  end

  it 'detects block parameter return self from core methods' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      String.new.tap do |str|
        str
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(2, 8))
    expect(clip.infer.tag).to eq('String')
  end

  it 'gets return types from param type tags' do
    map = Solargraph::SourceMap.load_string(%(

      # @yieldparam [Array]
      def yielder
      end

      # @param things [Set]
      yielder do |things|
        things
      end
    ))
    expect(map.locals.first.return_type.tag).to eq('Set')
  end

  it 'gets return types from yieldreturn type tags' do
    map = Solargraph::SourceMap.load_string(%(

      # @yieldparam [Array]
      # @yieldreturn [Integer]
      # @return [Integer]
      def yielder(&blk)
        blk.yield
      end

      # @param things [Set]
      yielder do |things|
        123
      end
    ))
    expect(map.pins.size).to eq(3)
    expect(map.pins.map(&:class))
      .to eq([
               Solargraph::Pin::Namespace,
               Solargraph::Pin::Method,
               Solargraph::Pin::Block
             ])

    method = map.pins[1]
    expect(method.signatures.size).to eq(1)

    method_signature = method.signatures.first
    block_param = method_signature.parameters.last
    expect(block_param.name).to eq('blk')
    expect(block_param.return_type.to_s).to eq('Proc')
    expect(method_signature.parameters.size).to eq(1)
    block_signature = method_signature.block
    expect(block_signature.return_type.to_s).to eq('Integer')
    expect(block_signature.parameters.map(&:return_type).map(&:to_s)).to eq(['Array'])
    expect(method.detail).to eq('(&blk) => Integer')
    expect(method.documentation).to eq("Block Params:\n*  [Array] \n\nBlock Returns:\n* [Integer] \n\nReturns:\n* [Integer] \n\nVisibility: public")
    expect(method.return_type.tag).to eq('Integer')


    expect(map.locals.map(&:to_rbs)).to eq(['blk ::Proc', 'things Set'])
    expect(map.locals.map(&:return_type).map(&:to_s)).to eq(%w[Proc Set])
    expect(map.locals.map(&:decl)).to eq(%i[blockarg arg])
  end

  it 'detects near equivalents' do
    map1 = Solargraph::SourceMap.load_string(%(
      strings.each do |foo|
      end
    ))
    pin1 = map1.locals.select { |p| p.name == 'foo' }.first
    map2 = Solargraph::SourceMap.load_string(%(
      # A minor comment change
      strings.each do |foo|
      end
      ))
    pin2 = map2.locals.select { |p| p.name == 'foo' }.first
    expect(pin1.nearly?(pin2)).to be(true)
  end

  it 'infers fully qualified namespaces' do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar
          # @return [Array<Bar>]
          def baz; end
        end
      end
      Foo::Bar.new.baz.each do |par|
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.select { |p| p.name == 'par' }.first
    type = pin.typify(api_map)
    expect(type.namespace).to eq('Foo::Bar')
  end

  it 'merges near equivalents' do
    loc = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0))
    block = Solargraph::Pin::Block.new(location: loc, name: 'Foo')
    pin1 = Solargraph::Pin::Parameter.new(closure: block, name: 'bar')
    pin2 = Solargraph::Pin::Parameter.new(closure: block, name: 'bar', comments: 'a comment')
    expect(pin1.try_merge!(pin2)).to be(true)
  end

  it 'does not merge block parameters from different blocks' do
    loc = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0))
    block1 = Solargraph::Pin::Block.new(location: loc, name: 'Foo')
    block2 = Solargraph::Pin::Block.new(location: loc, name: 'Bar')
    pin1 = Solargraph::Pin::Parameter.new(closure: block1, name: 'bar')
    pin2 = Solargraph::Pin::Parameter.new(closure: block2, name: 'bar', comments: 'a comment')
    expect(pin1.try_merge!(pin2)).to be(false)
  end

  it 'infers undefined types by default' do
    source = Solargraph::Source.load_string(%(
      func do |foo|
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.select { |p| p.is_a?(Solargraph::Pin::Parameter) }.first
    # expect(pin.infer(api_map)).to be_undefined
    expect(pin.typify(api_map)).to be_undefined
    expect(pin.probe(api_map)).to be_undefined
  end

  it 'detects method parameter return types from @param tags' do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      def foo bar
      end
    ), 'file.rb')
    map = Solargraph::SourceMap.map(source)
    expect(map.locals.length).to eq(1)
    expect(map.locals.first.name).to eq('bar')
    expect(map.locals.first.return_type.tag).to eq('String')
  end

  it 'tracks its index' do
    smap = Solargraph::SourceMap.load_string(%(
      def foo bar
      end
    ))
    pin = smap.locals.select { |p| p.name == 'bar' }.first
    expect(pin.index).to eq(0)
  end

  it 'detects unnamed @param tag types' do
    smap = Solargraph::SourceMap.load_string(%(
      # @param [String]
      def foo bar
      end
    ))
    pin = smap.locals.select { |p| p.name == 'bar' }.first
    expect(pin.return_type.tag).to eq('String')
  end

  it 'infers return types from method reference tags' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param bla [String]
        def bar(bla)
        end
        # @param qux [Integer]
        # @param (see Foo#bar)
        def baz(qux, bla)
          bla._
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [8, 14])
    paths = clip.complete.pins.map(&:path)
    expect(paths).to include('String#upcase')
  end

  it 'infers return types from relative method reference tags' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param bla [String]
        def bar(bla)
        end
        # @param (see #bar)
        def baz(bla)
          bla._
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 14])
    paths = clip.complete.pins.map(&:path)
    expect(paths).to include('String#upcase')
  end

  it 'infers return types recursively' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param bla [String]
        def bar(bla)
        end
        # @param (see Foo#bar)
        def baz(bla)
        end
      end
      class Other
        # @param (see Foo#baz)
        def deep(bla)
          bla._
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [12, 14])
    paths = clip.complete.pins.map(&:path)
    expect(paths).to include('String#upcase')
  end

  it 'avoids infinite recursion in reference tags' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param (see #baz)
        def bar(bla)
        end
        # @param (see #bar)
        def baz(bla)
          bla._
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 14])
    paths = clip.complete.pins.map(&:path)
    expect(paths).to be_empty
  end

  it 'uses tags for documentation' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # The bar method
        # @param baz [String] The baz param
        def bar baz
          use(baz)
        end
      end
    ), 'test.rb')
    pin = smap.locals.first
    expect(pin.documentation).to include('The baz param')
    expect(pin.documentation).not_to include('The bar method')
  end

  it 'typifies from generic yield params' do
    # This test depends on RBS definitions for Array#each with generic yield params
    source = Solargraph::Source.load_string(%(
      # @return [Array<String>]
      def list_strings; end

      # @param str [String]
      # @return [void]
      def use_string str
        while x
          list = list_strings
          list.each do |s|
            use_string(s)
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    api_map.get_path_pins('Array#each').first
    clip = api_map.clip_at('test.rb', [10, 23])
    pin = clip.define.first
    type = pin.typify(api_map)
    expect(type.tag).to eq('String')
  end

  context 'for instance methods' do
    it 'infers types from optarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          def foo bar = 'bar'
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end

    it 'infers types from kwoptarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          def foo bar: 'bar'
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end
  end

  context 'for class methods' do
    it 'infers types from optarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          def self.foo bar = 'bar'
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end

    it 'infers types from kwoptarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          def self.foo bar: 'bar'
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end

    it 'infers types from kwoptarg code' do
      source = Solargraph::Source.load_string(%(
        class Example
          def self.foo bar: Hash.new
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.name).to eq('Hash')
    end
  end

  context 'for singleton methods' do
    it 'infers types from optarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          class << self
            def self.foo bar = 'bar'
            end
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end

    it 'infers types from kwoptarg values' do
      source = Solargraph::Source.load_string(%(
        class Example
          class << self
            def self.foo bar: 'bar'
            end
          end
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      pin = api_map.source_map('test.rb').locals.first
      type = pin.probe(api_map)
      expect(type.simple_tags).to eq('String')
    end
  end
end
