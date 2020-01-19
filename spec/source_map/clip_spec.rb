describe Solargraph::SourceMap::Clip do
  let(:api_map) { Solargraph::ApiMap.new }

  it "completes constants" do
    orig = Solargraph::Source.load_string('File')
    updater = Solargraph::Source::Updater.new(nil, 1, [
      Solargraph::Source::Change.new(Solargraph::Range.from_to(0, 4, 0, 4), '::')
    ])
    source = orig.synchronize(updater)
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:path)).to include('File::SEPARATOR')
  end

  it "completes class variables" do
    source = Solargraph::Source.load_string('@@foo = 1; @@f', 'test.rb')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@@foo')
  end

  it 'completes class variables in open scopes' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @@bar = 'bar'
        @@b
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 11])
    pins = clip.complete.pins
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@@bar')
  end

  it 'uses scope gates to detect class variables' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @@foo = 'foo'
      end
      class Bar
        Foo.class_eval do
          @@f
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 13])
    expect(clip.complete.pins).to be_empty
  end

  it "completes instance variables" do
    source = Solargraph::Source.load_string('@foo = 1; @f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@foo')
  end

  it "completes global variables" do
    source = Solargraph::Source.load_string('$foo = 1; $f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('$foo')
  end

  it "completes symbols" do
    source = Solargraph::Source.load_string('$foo = :foo; :f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 15))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include(':foo')
  end

  it "completes core constants and methods" do
    source = Solargraph::Source.load_string('')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    paths = comp.pins.map(&:path)
    expect(paths).to include('String')
    expect(paths).to include('Kernel#puts')
  end

  it "defines core constants" do
    source = Solargraph::Source.load_string('String')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 0))
    clip = described_class.new(api_map, cursor)
    pins = clip.define
    expect(pins.map(&:path)).to include('String')
  end

  it "signifies core methods" do
    source = Solargraph::Source.load_string('File.dirname()')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, cursor)
    pins = clip.signify
    expect(pins.map(&:path)).to include('File.dirname')
  end

  it "detects local variables" do
    source = Solargraph::Source.load_string(%(
      x = '123'
      x
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(2, 0))
    clip = described_class.new(api_map, cursor)
    expect(clip.locals.map(&:name)).to include('x')
  end

  it "detects local variables passed into blocks" do
    source = Solargraph::Source.load_string(%(
      x = '123'
      y = x.split
      y.each do |z|
        z
      end
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(4, 0))
    clip = described_class.new(api_map, cursor)
    expect(clip.locals.map(&:name)).to include('x')
  end

  it "ignores local variables assigned after blocks" do
    source = Solargraph::Source.load_string(%(
      x = []
      x.each do |y|
        y
      end
      z = '123'
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(3, 0))
    clip = described_class.new(api_map, cursor)
    expect(clip.locals.map(&:name)).not_to include('z')
  end

  it "puts local variables first in completion results" do
    source = Solargraph::Source.load_string(%(
      def p2
      end
      p1 = []
      p
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(4, 7))
    clip = described_class.new(api_map, cursor)
    pins = clip.complete.pins
    expect(pins.first).to be_a(Solargraph::Pin::LocalVariable)
    expect(pins.first.name).to eq('p1')
  end

  it "completes constants only for leading double colons" do
    source = Solargraph::Source.load_string(%(
      ::_
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(1, 8))
    clip = described_class.new(api_map, cursor)
    pins = clip.complete.pins
    expect(pins.all?{ |p| p.is_a?(Solargraph::Pin::Namespace) || p.is_a?(Solargraph::Pin::Constant) }).to be(true)
  end

  it "completes partially completed constants" do
    source = Solargraph::Source.load_string(%(
      class Foo; end
      F
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(2, 7))
    pins = clip.complete.pins
    expect(pins.map(&:path)).to include('Foo')
  end

  it "completes partially completed inner constants" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
      end
      Foo::B
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(4, 12))
    pins = clip.complete.pins
    expect(pins.length).to eq(1)
    expect(pins.map(&:path)).to include('Foo::Bar')
  end

  it "completes unstarted inner constants" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar; end
      end
      Foo::
      puts
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    cursor = api_map.clip_at('test.rb', Solargraph::Position.new(4, 11))
    pins = cursor.complete.pins
    expect(pins.length).to eq(1)
    expect(pins.map(&:path)).to include('Foo::Bar')
  end

  it "does not define arbitrary comments" do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_reader :bar
        # My baz method
        def baz; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(3, 10))
    expect(clip.define).to be_empty
  end

  it "infers types from named macros" do
    source = Solargraph::Source.load_string(%(
      # @!macro firstarg
      #   @return [$1]
      class Foo
        # @macro firstarg
        def bar klass
        end
      end
      Foo.new.bar(String)
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(8, 14))
    expect(clip.infer.tag).to eq('String')
  end

  it "infers method types from return nodes" do
    source = Solargraph::Source.load_string(%(
      def foo
        String.new(from_object)
      end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(4, 6))
    type = clip.infer
    expect(type.tag).to eq('String')
  end

  it "infers multiple method types from return nodes" do
    source = Solargraph::Source.load_string(%(
      def foo
        if x
          'one'
        else
          1
        end
      end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(8, 6))
    type = clip.infer
    expect(type.to_s).to eq('String, Integer')
  end

  it "infers return types from method calls" do
    source = Solargraph::Source.load_string(%(
      # @return [Hash]
      def foo(arg); end
      def bar
        foo(1000)
      end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(6, 6))
    type = clip.infer
    expect(type.tag).to eq('Hash')
  end

  it "infers return types from local variables" do
    source = Solargraph::Source.load_string(%(
      def foo
        x = 1
        y = 'one'
        x
      end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(6, 6))
    type = clip.infer
    expect(type.tag).to eq('Integer')
  end

  it "infers return types from instance variables" do
    source = Solargraph::Source.load_string(%(
      def foo
        @foo ||= {}
      end
      def bar
        @foo
      end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(7, 6))
    type = clip.infer
    expect(type.tag).to eq('Hash')
  end

  it "infers implicit return types from singleton methods" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def self.bar
          @bar = 'bar'
        end
      end
      Foo.bar
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(6, 10))
    type = clip.infer
    expect(type.tag).to eq('String')
  end

  it "infers undefined for empty methods" do
    source = Solargraph::Source.load_string(%(
      def foo; end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(2, 6))
    type = clip.infer
    expect(type).to be_undefined
  end

  it "handles missing type annotations in @type tags" do
    source = Solargraph::Source.load_string(%(
      # Note the type is `String` instead of `[String]`
      # @type String
      x = foo_bar
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(3, 7))
    expect {
      expect(clip.infer).to be_undefined
    }.not_to raise_error
  end

  it "completes unfinished constant chains with trailing nodes" do
    # The variable assignment at the end of the constant reference gets parsed
    # as part of the constant chain, e.g., `Foo::Bar::baz`
    orig = Solargraph::Source.load_string(%(
      module Foo
        module Bar
          module Baz; end
        end
      end
      Foo::Bar
      baz = 'baz'
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    updater = Solargraph::Source::Updater.new('test.rb', 1, [
      Solargraph::Source::Change.new(Solargraph::Range.from_to(6, 14, 6, 14), '::')
    ])
    source = orig.synchronize(updater)
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(6, 16))
    expect(clip.complete.pins.map(&:path)).to eq(['Foo::Bar::Baz'])
  end

  it "resolves conflicts between namespaces names" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def root_method; end
      end
      module Other
        class Foo
          def other_method; end
        end
      end
      module Other
        # @type [Foo]
        foo1 = make_foo
        foo1._
        # @type [::Foo]
        foo2 = make_foo
        foo2._
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip1a = api_map.clip_at('test.rb', Solargraph::Position.new(12, 9))
    expect(clip1a.infer.to_s).to eq('Other::Foo')
    clip1b = api_map.clip_at('test.rb', Solargraph::Position.new(12, 13))
    expect(clip1b.complete.pins.map(&:path)).to include('Other::Foo#other_method')
    expect(clip1b.complete.pins.map(&:path)).not_to include('Foo#root_method')

    clip2a = api_map.clip_at('test.rb', Solargraph::Position.new(15, 9))
    expect(clip2a.infer.rooted?).to be(true)
    expect(clip2a.infer.to_s).to eq('Foo')
    clip2b = api_map.clip_at('test.rb', Solargraph::Position.new(15, 13))
    expect(clip2b.complete.pins.map(&:path)).not_to include('Other::Foo#other_method')
    expect(clip2b.complete.pins.map(&:path)).to include('Foo#root_method')
  end

  it "completes methods based on visibility and context" do
    source = Solargraph::Source.load_string(%(
      class Foo
        protected
        def prot_method; end
        private
        def priv_method; end
        def bar
          _
        end
        Foo.new._
      end
      Foo.new._
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip1 = api_map.clip_at('test.rb', Solargraph::Position.new(7, 10))
    paths1 = clip1.complete.pins.map(&:path)
    expect(paths1).to include('Foo#prot_method')
    expect(paths1).to include('Foo#priv_method')

    clip2 = api_map.clip_at('test.rb', Solargraph::Position.new(9, 16))
    paths2 = clip2.complete.pins.map(&:path)
    expect(paths2).to include('Foo#prot_method')
    expect(paths2).not_to include('Foo#priv_method')

    clip3 = api_map.clip_at('test.rb', Solargraph::Position.new(11, 14))
    paths3 = clip3.complete.pins.map(&:path)
    expect(paths3).not_to include('Foo#prot_method')
    expect(paths3).not_to include('Foo#priv_method')
  end

  it "processes @yieldself tags in completions" do
    source = Solargraph::Source.load_string(%(
      class Par
        def action; end
        private
        def hidden; end
      end
      class Foo
        # @yieldself [Par]
        def bar; end
      end
      Foo.new.bar do
        x
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', [11, 8])
    expect(clip.complete.pins.map(&:path)).to include('Par#action')
    expect(clip.complete.pins.map(&:path)).to include('Par#hidden')
  end

  it "processes @yieldpublic tags in completions" do
    source = Solargraph::Source.load_string(%(
      class Par
        def action; end
        private
        def hidden; end
      end
      class Foo
        # @yieldpublic [Par]
        def bar; end
      end
      Foo.new.bar do
        x
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', [11, 8])
    expect(clip.complete.pins.map(&:path)).to include('Par#action')
    expect(clip.complete.pins.map(&:path)).not_to include('Par#hidden')
  end

  it "infers instance variable types in rebound blocks" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def initialize
          @foo = ''
        end
      end
      Foo.new.instance_eval do
        @foo
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.tag).to eq('String')
  end

  it "completes instance variable methods in rebound blocks" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def initialize
          @foo = ''
        end
      end
      Foo.new.instance_eval do
        @foo._
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 13])
    expect(clip.complete.pins.map(&:path)).to include('String#upcase')
  end

  it 'infers class instance variable types in rebound blocks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @foo = ''
      end
      Foo.class_eval do
        @foo
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [5, 8])
    expect(clip.infer.tag).to eq('String')
  end

  it "completes extended class methods" do
    source = Solargraph::Source.load_string(%(
      module Extender
        def foobar; end
      end

      class Extended
        extend Extender
        foo
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 11])
    expect(clip.complete.pins.map(&:name)).to include('foobar')
  end

  it 'infers explicit return types from <Class>.new methods' do
    source = Solargraph::Source.load_string(%(
      class Value
        # @return [Class]
        def self.new
        end
      end
      value = Value.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 11])
    expect(clip.infer.tag).to eq('Class')
  end

  it 'infers Object from Class#new' do
    source = Solargraph::Source.load_string(%(
      cls = Class.new
      cls.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [2, 11])
    expect(clip.infer.tag).to eq('Object')
  end

  it 'infers Object from Class.new.new' do
    source = Solargraph::Source.load_string(%(
      Class.new.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [1, 17])
    expect(clip.infer.tag).to eq('Object')
  end

  it 'completes class instance variables in the namespace' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @bar = 'bar'
        @b
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 10])
    names = clip.complete.pins.map(&:name)
    expect(names).to include('@bar')
  end

  it 'infers variable types from multiple return nodes' do
    source = Solargraph::Source.load_string(%(
      x = if foo
        'one'
      else
        [two]
      end
      x
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 7])
    expect(clip.infer.to_s).to eq('String, Array')
  end

  it 'detects scoped methods in rebound blocks' do
    source = Solargraph::Source.load_string(%(
      class MyClass
        def my_method
        end
      end
      object = MyClass.new
      object.instance_eval do
        m
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 9])
    expect(clip.complete.pins.map(&:path)).to include('MyClass#my_method')
  end

  it 'infers types from scoped methods in rebound blocks' do
    source = Solargraph::Source.load_string(%(
      class InnerClass
        def inner_method
          @inner_method = ''
        end
      end

      class MyClass
        # @yieldself [InnerClass]
        def my_method
          @my_method ||= 'mines'
        end
      end

      MyClass.new.my_method do
        inner_method
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [15, 20])
    expect(clip.infer.tag).to eq('String')
  end

  it 'finds instance methods inside private classes' do
    source = Solargraph::Source.load_string(%(
      module First
        module Second
          class Sub
            def method1; end
            def method2
              meth
            end
          end
          private_constant :Sub
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 18])
    expect(clip.complete.pins.map(&:path)).to include('First::Second::Sub#method1')
    expect(clip.complete.pins.map(&:path)).to include('First::Second::Sub#method2')
  end

  it 'avoids completion inside strings for unsynchronized sources' do
    source = Solargraph::Source.load_string(%(
      'one two'
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    updater = Solargraph::Source::Updater.new(
      'test.rb',
      1,
      [
        Solargraph::Source::Change.new(Solargraph::Range.from_to(1, 6, 1, 6), '.')
      ]
    )
    updated = source.start_synchronize(updater)
    cursor = updated.cursor_at(Solargraph::Position.new(1, 7))
    clip = api_map.clip(cursor)
    expect(clip.complete.pins).to be_empty
  end

  it 'resolves self return types to the current scope' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [self]
        def self.make; end
        def foo_method; end
      end
      class Bar < Foo
        def bar_method; end
      end
      Bar.make.bar_method
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.tag).to eq('Bar')
    clip = api_map.clip_at('test.rb', [9, 15])
    expect(clip.define.first.path).to eq('Bar#bar_method')
  end

  it 'resolves methods when completing base self types' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [self]
        def self.make; end
        def foo_method; end
      end
      class Bar < Foo
        def bar_method; end
      end
      Bar.make.b
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [9, 15])
    expect(clip.complete.pins.map(&:path)).to include('Bar#bar_method')
  end

  it 'infers Hash value types' do
    source = Solargraph::Source.load_string(%(
      # @type [Hash{String => File}]
      h = {}
      h['file.txt']
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 19])
    expect(clip.infer.tag).to eq('File')
  end

  it 'infers self in instance methods' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def initialize
          self
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 10])
    type = clip.infer
    expect(type.tag).to eq('Foo')    
  end

  it 'infers deep variables' do
    code = "v0 = []\n"
    # 100 is an arbitrary depth that should be way higher than most users will
    # encounter in practice
    100.times do |index|
      code += "v#{index + 1} = v#{index}\n"
    end
    code += "v100"
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [code.lines.length - 1, 0])
    type = clip.infer
    expect(type.tag).to eq('Array')
  end

  it 'completes keyword parameters' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar baz: ''
        end
      end
      Foo.new.bar(b)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [5, 19])
    expect(clip.complete.pins.map(&:name)).to include('baz:')
  end

  it 'ignores shadowed keyword parameters' do
    source = Solargraph::Source.load_string(%(
      class Sup
        def foo bar: ''
        end
      end
      class Sub < Sup
        def foo bar
        end
      end
      Sub.new.foo(b)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [9, 19])
    expect(clip.complete.pins.map(&:name)).not_to include('bar:')
  end

  it 'includes tagged params for double splats' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [String]
        def bar **splat
        end
      end
      Foo.new.bar(b)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 19])
    expect(clip.complete.pins.map(&:name)).to include('baz:')
  end

  it 'includes tagged params for trailing hashes' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [String]
        def bar opts = {}
        end
      end
      Foo.new.bar(b)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 19])
    expect(clip.complete.pins.map(&:name)).to include('baz:')
  end

  it 'infers Array#[] types from overloads' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      arr = []
      arr[0..2]
      arr[0, 2]
      arr[1000]
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(3, 15))
    expect(clip.infer.to_s).to eq('Array<String>')
    clip = map.clip_at('test.rb', Solargraph::Position.new(4, 15))
    expect(clip.infer.to_s).to eq('Array<String>')
    clip = map.clip_at('test.rb', Solargraph::Position.new(5, 15))
    expect(clip.infer.to_s).to eq('String')
  end

  it 'infers overloads with splats' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @overload bar(num1, *num2)
        #   @return [String]
        def bar; end
      end
      Foo.new.bar(1)
      Foo.new.bar(1, 2)
      Foo.new.bar(1, 2, 3)
      Foo.new.bar
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 14])
    expect(clip.infer.to_s).to eq('String')
    clip = api_map.clip_at('test.rb', [7, 14])
    expect(clip.infer.to_s).to eq('String')
    clip = api_map.clip_at('test.rb', [8, 14])
    expect(clip.infer.to_s).to eq('String')
    clip = api_map.clip_at('test.rb', [9, 14])
    expect(clip.infer).to be_undefined  
  end

  it 'follows scope gates' do
    source = Solargraph::Source.load_string(%(
      module Foo
        FOO_CONST = 'foo_const'
        module Bar; end
      end
      module Foo
        module Bar
          F
        end
      end
      module Foo::Bar
        F
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 11])
    expect(clip.complete.pins.map(&:name)).to include('FOO_CONST')
    clip = api_map.clip_at('test.rb', [11, 9])
    expect(clip.complete.pins.map(&:name)).not_to include('FOO_CONST')
  end

  it 'detects sibling constants in open scope gates' do
    source = Solargraph::Source.load_string(%(
      class Super
        class One; end
      end
      class Super
        class Two
          def one
            One.n
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    clip = api_map.clip_at('test.rb', [7, 15])
    pin = clip.infer
    expect(pin.tag).to eq('Class<Super::One>')

    clip = api_map.clip_at('test.rb', [7, 17])
    pin = clip.complete.pins.select { |p| p.name == 'new' }.first
    expect(pin.path).to eq('Class#new')
  end

  it 'completes clips from repaired sources ending with a period' do
    source = Solargraph::Source.load_string(%(
      nums = '1,2,3'.split(',')
    ), 'test.rb')
    updater = Solargraph::Source::Updater.new('test.rb', 1, [
      Solargraph::Source::Change.new(
        Solargraph::Range.from_to(1, 31, 1, 31),
        '.'
      )
    ])
    updated = source.start_synchronize(updater)
    api_map = Solargraph::ApiMap.new
    api_map.map updated
    clip = api_map.clip_at('test.rb', [1, 32])
    paths = clip.complete.pins.map(&:path)
    expect(paths).to include('Array#length')
  end

  it 'infers using yielded blocks' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      list = []
      sub = list.select { |str| str.ascii_only? }
      sub
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [4, 6])
    expect(clip.infer.tag).to eq('Array<String>')
  end

  it 'completes from repaired sources with missing nodes' do
    source = Solargraph::Source.load_string(%(
      x = []
      
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    updater = Solargraph::Source::Updater.new('test.rb', 1, [
      Solargraph::Source::Change.new(Solargraph::Range.from_to(2, 6, 2, 6), 'x.')
    ])
    updated = source.start_synchronize(updater)
    api_map.map updated
    clip = api_map.clip_at('test.rb', [2, 8])
    expect(clip.complete.pins.first.path).to start_with('Array#')
  end

  it 'selects local variables using gated scopes' do
    source = Solargraph::Source.load_string(%(
      lvar1 = 'lvar1'
      module MyModule
        lvar2 = 'lvar2'

      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [4, 0])
    names = clip.complete.pins.map(&:name)
    expect(names).not_to include('lvar1')
    expect(names).to include('lvar2')
    clip = api_map.clip_at('test.rb', [6, 0])
    names = clip.complete.pins.map(&:name)
    expect(names).to include('lvar1')
    expect(names).not_to include('lvar2')
  end

  it 'includes Kernel method calls in namespaces' do
    source = Solargraph::Source.load_string(%(
      class Foo
        caller
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [2, 10])
    paths = clip.define.map(&:path)
    expect(paths).to include('Kernel#caller')
    paths = clip.complete.pins.map(&:path)
    expect(paths).to include('Kernel#caller')
  end

  it 'excludes Kernel method calls in chains' do
    source = Solargraph::Source.load_string(%(
      Object.new.caller
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [1, 18])
    paths = clip.complete.pins.map(&:path)
    expect(paths).not_to include('Kernel#caller')
  end

  it 'detects local variables across closures' do
    source = Solargraph::Source.load_string(%(
      class Mod
        def meth
          arr = []
          1.times do
            arr
          end
          arr
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 11])
    expect(clip.infer.tag).to eq('Array')
    clip = api_map.clip_at('test.rb', [5, 12])
    expect(clip.infer.tag).to eq('Array')
    clip = api_map.clip_at('test.rb', [7, 10])
    expect(clip.infer.tag).to eq('Array')
  end
end
