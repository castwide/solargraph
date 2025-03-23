describe Solargraph::SourceMap::Clip do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'completes constants' do
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

  it 'completes class variables' do
    source = Solargraph::Source.load_string('@@foo = 1; @@f', 'test.rb')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@@foo')
  end

  it 'completes class instance variables' do
    source = Solargraph::Source.load_string('class Foo; @foo = 1; @f; end', 'test.rb')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 22))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@foo')
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

  it 'completes class instance variables in open scopes' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @bar = 'bar'
        @b
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 10])
    pins = clip.complete.pins
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@bar')
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

  it 'uses scope gates to detect class instance variables' do
    source = Solargraph::Source.load_string(%(
      class Foo
        @foo = 'foo'
      end
      class Bar
        Foo.class_eval do
          @f
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 12])
    expect(clip.complete.pins.map(&:name)).to eq (['@foo'])
  end

  it 'completes instance variables' do
    source = Solargraph::Source.load_string('@foo = 1; @f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@foo')
  end

  it 'completes global variables' do
    source = Solargraph::Source.load_string('$foo = 1; $f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('$foo')
  end

  it 'completes symbols' do
    source = Solargraph::Source.load_string('$foo = :foo; :f', 'test.rb')
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 15))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include(':foo')
  end

  it 'completes core constants and methods' do
    source = Solargraph::Source.load_string('')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    paths = comp.pins.map(&:path)
    expect(paths).to include('String')
    expect(paths).to include('Kernel#puts')
  end

  it 'defines core constants' do
    source = Solargraph::Source.load_string('String')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 0))
    clip = described_class.new(api_map, cursor)
    pins = clip.define
    expect(pins.map(&:path)).to include('String')
  end

  it 'signifies core methods' do
    source = Solargraph::Source.load_string('File.dirname()')
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, cursor)
    pins = clip.signify
    expect(pins.map(&:path)).to include('File.dirname')
  end

  it 'detects local variables' do
    source = Solargraph::Source.load_string(%(
      x = '123'
      x
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(2, 0))
    clip = described_class.new(api_map, cursor)
    expect(clip.locals.map(&:name)).to include('x')
  end

  it 'detects local variables passed into blocks' do
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

  it 'ignores local variables assigned after blocks' do
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

  it 'puts local variables first in completion results' do
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

  it 'completes constants only for leading double colons' do
    source = Solargraph::Source.load_string(%(
      ::_
    ))
    api_map.map source
    cursor = source.cursor_at(Solargraph::Position.new(1, 8))
    clip = described_class.new(api_map, cursor)
    pins = clip.complete.pins
    expect(pins.all? { |p| p.is_a?(Solargraph::Pin::Namespace) || p.is_a?(Solargraph::Pin::Constant) }).to be(true)
  end

  it 'completes partially completed constants' do
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

  it 'completes partially completed inner constants' do
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

  it 'completes unstarted inner constants' do
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

  it 'does not define arbitrary comments' do
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

  it 'infers types from named macros' do
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

  it 'infers method types from return nodes' do
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

  it 'infers multiple method types from return nodes' do
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

  it 'infers return types from method calls' do
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

  it 'infers complex return types from method calls' do
    source = Solargraph::Source.load_string(%(
      # @return [String, Array]
      def foo; end
      var = foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(3, 7))
    type = clip.infer
    expect(type.to_s).to eq('String, Array')
  end

  it 'infers return types from local variables' do
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

  it 'infers return types from instance variables' do
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

  it 'infers implicit return types from singleton methods' do
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

  it 'infers nil for empty methods' do
    source = Solargraph::Source.load_string(%(
      def foo; end
      foo
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(2, 6))
    type = clip.infer
    expect(type.tag).to eq('nil')
  end

  it 'handles missing type annotations in @type tags' do
    source = Solargraph::Source.load_string('
      # Note the type is `String` instead of `[String]`
      # @type String
      x = foo_bar
    ', 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(3, 7))
    expect do
      expect(clip.infer).to be_undefined
    end.not_to raise_error
  end

  it 'completes unfinished constant chains with trailing nodes' do
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

  it 'resolves conflicts between namespaces names' do
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
    # expect(clip2a.infer.rooted?).to be(true)
    expect(clip2a.infer.to_s).to eq('Foo')
    clip2b = api_map.clip_at('test.rb', Solargraph::Position.new(15, 13))
    expect(clip2b.complete.pins.map(&:path)).not_to include('Other::Foo#other_method')
    expect(clip2b.complete.pins.map(&:path)).to include('Foo#root_method')
  end

  it 'completes methods based on visibility and context' do
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

  it 'processes @yieldreceiver tags in completions' do
    source = Solargraph::Source.load_string(%(
      class Par
        def action; end
        private
        def hidden; end
      end
      class Foo
        # @yieldreceiver [Par]
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

  it 'processes @yieldreceiver from blocks in class method calls' do
    source = Solargraph::Source.load_string(%(
      class Par
        # @yieldreceiver [self]
        def self.process; end
      end
      class Sub < Par
        def local; end

        process do
          loc
        end
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', [9, 12])
    expect(clip.complete.pins.map(&:path)).to include('Sub#local')
  end

  it 'processes @yieldreceiver in variable contexts' do
    source = Solargraph::Source.load_string(%(
      class Par
        def action; end
        private
        def hidden; end
      end
      class Foo
        # @yieldreceiver [Par]
        def bar; end
      end
      foo = Foo.new
      foo.bar do
        x
      end
    ), 'file.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('file.rb', [12, 8])
    expect(clip.complete.pins.map(&:path)).to include('Par#action')
    expect(clip.complete.pins.map(&:path)).to include('Par#hidden')
  end

  it 'infers instance variable types in rebound blocks' do
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

  it 'completes instance variable methods in rebound blocks' do
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

  it 'completes instance variable methods in define_method blocks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def initialize
          @foo = ''
          define_method(:test3) { @foo._ } # only handle Module#define_method, other pin is ignored..
        end
        define_method(:test) do
          @foo._
        end
      end
      Foo.define_method(:test2) do
        @foo._
        define_method(:test4) { @foo._ } # only handle Module#define_method, other pin is ignored..
      end
      Foo.class_eval do
        define_method(:test5) { @foo._ }
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    [[4, 39], [7, 15], [11, 13], [12, 37], [15, 37]].each do |loc|
      clip = api_map.clip_at('test.rb', loc)
      paths = clip.complete.pins.map(&:path)
      expect(paths).to include('String#upcase'), -> { %(expected #{paths} at #{loc} to include "String#upcase") }
    end
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

  it 'completes extended class methods' do
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

  it 'infers BasicObject from Class#new' do
    source = Solargraph::Source.load_string(%(
      cls = Class.new
      cls.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [2, 11])
    expect(clip.infer.tag).to eq('BasicObject')
  end

  it 'infers BasicObject from Class.new.new' do
    source = Solargraph::Source.load_string(%(
      Class.new.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [1, 17])
    expect(clip.infer.tag).to eq('BasicObject')
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
        # @yieldreceiver [InnerClass]
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

  it 'finds inferred type definitions' do
    source = Solargraph::Source.load_string(%(
      class OtherNamespace::MyClass; end
      module SomeNamespace
        class Foo
          # @return [self]
          def self.make; end
        end
        class Bar < Foo
          # @return [Class<Foo>, Bar, OtherNamespace::MyClass]
          def foo_method;end

          def bar_method
            local_variable = Foo.new
            other_variable = local_variable
          end
        end
      end
      SomeNamespace::Bar.make.foo_method
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [13, 33])
    expect(clip.types.map(&:path)).to eq(['SomeNamespace::Foo']) # other_variable
    clip = api_map.clip_at('test.rb', [17, 33])
    expect(clip.types.map(&:path)).to eq(['SomeNamespace::Foo', 'SomeNamespace::Bar', 'OtherNamespace::MyClass'])
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
    code += 'v100'
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

  it 'infers unique variable type from ternary operator when used as lvalue' do
    source = Solargraph::Source.load_string(%(
      def foo a
        a = (true ? 'foo' : 'bar') + 'baz'
        a
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [3, 8])
    expect(clip.infer.to_s).to eq('String')
  end

  xit 'infers complex variable type from ternary operator' do
    source = Solargraph::Source.load_string(%(
      def foo a
        type = (a == 123 ? 'foo' : 456)
        type
      end
      foo(932)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [5, 14])
    expect(clip.infer.to_s).to eq('String, Integer')
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
    expect(clip.infer.to_s).to eq('Array<String>, nil')
    clip = map.clip_at('test.rb', Solargraph::Position.new(4, 15))
    expect(clip.infer.to_s).to eq('Array<String>, nil')
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
    # @todo This assertion might be invalid, given that the signature expects
    #   at least one argument
    # clip = api_map.clip_at('test.rb', [9, 14])
    # expect(clip.infer.tag).to eq('nil')
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
    source = Solargraph::Source.load_string("\n      x = []\n      ", 'test.rb')
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

  it 'uses arguments to infer from overloaded methods' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      a = []
      i1 = 0
      i2 = 5
      b = a[i2, i2]
      b # should be Array<String>
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [6, 6])
    expect(clip.infer.tag).to eq('Array<String>')
  end

  it 'excludes local variables from chained call resolution' do
    source = Solargraph::Source.load_string(%(
      a = 1 # => Integer
      a.a   # => undefined (Integer#a does not exist)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [2, 9])
    expect(clip.infer.tag).to eq('undefined')
  end

  it 'completes constants with the nearest pins' do
    source = Solargraph::Source.load_string(%(
      module Outer
        class String
          def self.dammit; end
        end
      end
      module Outer
        module Inner
          Strin
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [8, 15])
    expect(clip.complete.pins.first.path).to eq('Outer::String')
  end

  it 'signifies nested methods' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end

        def two arg2
        end
      end

      Foo.new.one(Foo.new.two())
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [9, 30])
    expect(clip.signify.first.path).to eq('Foo#two')
  end

  it 'signifies unsynchronized sources updated with commas' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two(x))
    ), 'test.rb')
    updater = Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [
        Solargraph::Source::Change.new(Solargraph::Range.from_to(7, 32, 7, 32), ',')
      ]
    )
    updated = source.start_synchronize(updater)
    api_map = Solargraph::ApiMap.new
    api_map.map updated
    clip = api_map.clip_at('test.rb', [7, 33])
    expect(clip.signify.first.path).to eq('Foo#one')
  end

  it 'signifies empty parentheses' do
    src = Solargraph::Source.load_string %(
      class Foo
        def bar baz, key: ''
        end
      end
      Foo.new.bar()
    ), 'file.rb', 0
    api_map = Solargraph::ApiMap.new
    api_map.map src
    clip = api_map.clip_at('file.rb', [5, 18])
    expect(clip.signify.first.path).to eq('Foo#bar')
  end

  it 'does not signify calls without parentheses' do
    source = Solargraph::Source.load_string %(
      class Foo
        def bar baz, key: ''
        end
      end
      Foo.new.bar
    ), 'test.rb', 0
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [5, 17])
    expect(clip.signify).to be_empty
  end

  it 'signifies unsynchronized sources updated with parentheses' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two)
    ), 'test.rb')
    updater = Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [
        Solargraph::Source::Change.new(Solargraph::Range.from_to(7, 29, 7, 29), '()')
      ]
    )
    updated = source.start_synchronize(updater)
    api_map = Solargraph::ApiMap.new
    api_map.map updated
    clip = api_map.clip_at('test.rb', [7, 30])
    expect(clip.signify.first.path).to eq('Foo#two')
  end

  it 'signifies sources with trailing commas' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two(x,))
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 32])
    expect(clip.signify.first.path).to eq('Foo#two')
  end

  it 'signifies sources with trailing commas in nested calls' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two(x, y),)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 36])
    expect(clip.signify.first.path).to eq('Foo#one')
  end

  it 'signifies sources with trailing commas and whitespace in nested calls' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two(x, y), )
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 36])
    expect(clip.signify.first.path).to eq('Foo#one')
    clip = api_map.clip_at('test.rb', [7, 37])
    expect(clip.signify.first.path).to eq('Foo#one')
  end

  it 'signifies unsynchronized sources with nested symbols' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def one arg1
        end
        def two arg2
        end
      end
      Foo.new.one(Foo.new.two())
    ), 'test.rb')
    updater = Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [
        Solargraph::Source::Change.new(Solargraph::Range.from_to(7, 30, 7, 30), 'F')
      ]
    )
    updated = source.start_synchronize(updater)
    api_map = Solargraph::ApiMap.new
    api_map.map updated
    clip = api_map.clip_at('test.rb', [7, 31])
    expect(clip.signify.first.path).to eq('Foo#two')
  end

  it 'finds constants in superclasses' do
    source = Solargraph::Source.load_string(%(
      class A
        class AA
        end
      end

      class B < A
        AA
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [7, 8])
    pins = clip.define
    expect(pins).to be_one
    expect(pins.first.path).to eq('A::AA')
  end

  it 'defines nearest constants' do
    source = Solargraph::Source.load_string(%(
      module A
        module AA
          class Gen
            def a
              pp a = A::Gen # infer to A::AA::Gen
              pp b = A::Gen::BB # can't infer
            end
          end
        end

        module Gen
          class BB; end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [5, 25])
    expect(clip.define.first.path).to eq('A::Gen')
    clip = api_map.clip_at('test.rb', [6, 30])
    expect(clip.define.first.path).to eq('A::Gen::BB')
  end

  it 'completes YARD tags' do
    source = Solargraph::Source.load_string(%(
      class TaggedExample
      end
      class CallerExample
        # @return [Tagg]
        def foo; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [4, 22])
    expect(clip.complete.pins.map(&:path)).to include('TaggedExample')
  end

  it 'completes generic YARD tags' do
    source = Solargraph::Source.load_string(%(
      class TaggedExample
      end
      class CallerExample
        # @return [Array<Tagg>]
        def foo; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [4, 29])
    expect(clip.complete.pins.map(&:path)).to include('TaggedExample')
  end

  it 'completes multiple YARD tags' do
    source = Solargraph::Source.load_string(%(
      class TaggedExample
      end
      class CallerExample
        # @return [String, Tagg]
        def foo; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    clip = api_map.clip_at('test.rb', [4, 31])
    expect(clip.complete.pins.map(&:path)).to include('TaggedExample')
  end

  it 'completes first of nested namespaces' do
    source = Solargraph::Source.load_string(%(
      module Foo; end
      module Foo::Bar; end
      module Foo
        class Bar::Baz; end
      end
      Foo::Bar::Baz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    names = api_map.clip_at('test.rb', [6, 12]).complete.pins.map(&:name)
    expect(names).to eq(['Bar'])
  end

  it 'completes subsequent nested namespaces' do
    source = Solargraph::Source.load_string(%(
      module Foo; end
      module Foo::Bar; end
      module Foo
        class Bar::Baz; end
      end
      Foo::Bar::Baz
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    names = api_map.clip_at('test.rb', [6, 17]).complete.pins.map(&:name)
    expect(names).to eq(['Baz'])
  end

  it 'completes all methods from union types' do
    source = Solargraph::Source.load_string(%(
      class Thing
        # @return [String, Array]
        def foo; end
      end
      Thing.new.foo.an
      Thing.new.foo.up
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)

    array_names = api_map.clip_at('test.rb', [5, 22]).complete.pins.map(&:name)
    expect(array_names).to eq(['any?'])

    string_names = api_map.clip_at('test.rb', [6, 22]).complete.pins.map(&:name)
    expect(string_names).to eq(['upcase', 'upcase!', 'upto'])
  end

  it 'completes global methods defined in top level scope inside class when referenced inside a namespace' do
    source = Solargraph::Source.load_string(%(
      def some_method;end

      class Thing
        def foo
          some_
        end
      end
      some_
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    pin_names = api_map.clip_at('test.rb', [5, 15]).complete.pins.map(&:name)
    expect(pin_names).to eq(['some_method'])
    pin_names = api_map.clip_at('test.rb', [8, 5]).complete.pins.map(&:name)
    expect(pin_names).to include('some_method')
  end

  it 'resolves name conflicts in pin identities' do
    source = Solargraph::Source.load_string(%(
      class A
        def x
          "string"
        end
      end

      a = A.new
      x = a.x
      x
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [9, 7])
    type = clip.infer
    expect(type.tag).to eq('String')
  end

  it 'picks correct overload in Hash#transform_values!' do
    source = Solargraph::Source.load_string(%(
      # @param t [Hash{String => Integer}]
      # @return [Hash{String => Integer}]
      def bar(t)
        a = t.transform_values! { |i| i + 3 }
        a
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 8])
    type = clip.infer
    expect(type.to_s).to eq('Hash{String => Integer}')
  end

  it 'picks correct overload in Enumerable#max_by' do
    source = Solargraph::Source.load_string(%(
      a = [1, 2, 3].max_by(&:abs)
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 6])
    type = clip.infer
    expect(type.to_s).to eq('Integer, nil')
  end

  it 'preserves duplicated types in tuple' do
    source = Solargraph::Source.load_string(%(
      # @type [Array(Array(Symbol, String, Array(Integer, Integer)))]
      a = 123
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [3, 6])
    type = clip.infer
    expect(type.to_s).to eq('Array(Array(Symbol, String, Array(Integer, Integer)))')
  end

  it 'infers overloads based on required parameters from Enumerable' do
    source = Solargraph::Source.load_string(%(
      # @return [Enumerable<String>]
      def foo; end

      a = foo.first
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 6])
    type = clip.infer
    expect(type.tag).to eq('String')
  end

  it 'infers overloads based on required parameters from Hash' do
    source = Solargraph::Source.load_string(%(
      # @return [Hash{String => Enumerable<String>}]
      def foo; end

      a = foo['bar']
      a
      b = a.first
      b
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 6])
    type = clip.infer
    expect(type.to_s).to eq('Enumerable<String>')
    clip = api_map.clip_at('test.rb', [7, 6])
    type = clip.infer
    expect(type.to_s).to eq('String, nil')
  end

  it 'infers yield parameters from self type defined methods in RBS' do
    source = Solargraph::Source.load_string(%(
      # @type [Enumerable<String>]
      a = ['a', 'b', 'c']
      a.each do |s|
        s
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    type = clip.infer
    expect(type.to_s).to eq('String')
  end

  it 'infers yield parameters from defined methods in RBS' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      a = ['a', 'b', 'c']
      a.each do |s|
        s
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    type = clip.infer
    expect(type.to_s).to eq('String')
  end

  it 'infers Object<self> from Class.new in core classes' do
    # Correct inference of Class.new depends on CoreFills, but we're testing
    # it here because it should eventually work from the core RBS alone.
    source = Solargraph::Source.load_string(%(
      Gem::Specification.new
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [1, 28])
    type = clip.infer
    expect(type.to_s).to eq('Gem::Specification')
  end

  it 'picks correct overload in Hash#transform_values!' do
    source = Solargraph::Source.load_string(%(
      # @param t [Hash{String => Integer}]
      # @return [Hash{String => Integer}]
      def bar(t)
        a = t.transform_values! { |i| i + 3 }
        a
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 8])
    type = clip.infer
    expect(type.to_s).to eq('Hash{String => Integer}')
  end

  it 'picks correct overload in Enumerable#max_by' do
    source = Solargraph::Source.load_string(%(
      a = [1, 2, 3].max_by(&:abs)
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 6])
    type = clip.infer
    expect(type.to_s).to eq('Integer, nil')
  end

  it 'picks correct overload in Hash#each_with_object and resolves return type' do
    source = Solargraph::Source.load_string(%(
      # @param klass [Class]
      # @param pin_class_hash [Hash{String => Class}]
      def pins_by_class klass, pin_class_hash
        # @type [Set<Integer>]
        s = Set.new
        pin_class_hash.each_with_object(s) { |(key, o), n| n.merge(o) if key <= klass }
      end

      out = pins_by_class Symbol, {}
      out
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [10, 6])
    type = clip.infer
    expect(type.to_s).to eq('Set<Integer>')
  end

  it 'erases unresolvable class generics' do
    source = Solargraph::Source.load_string(%(
      # @generic T
      class Foo
        # @return [generic<T>]
        def bar; baz; end
      end
      a = Foo.new.bar
      a
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 6])
    type = clip.infer
    expect(type.to_s).to eq('undefined')
  end

  it 'erases unresolvable method generics' do
    source = Solargraph::Source.load_string(%(
      # @generic T
      # @return [generic<T>] but I forgot to annotate the block parameters
      def bad_passthrough; yield; end

      a = bad_passthrough { 123 }
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 6])
    type = clip.infer
    expect(type.to_s).to eq('undefined')
  end

  it 'infers block-pass symbols from generics' do
    source = Solargraph::Source.load_string(%(
      array = [0, 1, 2]
      array.max_by(&:abs)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 13])
    type = clip.infer
    expect(type.to_s).to eq('Integer, nil')
  end

  it 'infers block-pass symbols with variant yields' do
    source = Solargraph::Source.load_string(%(
      array = [0]
      array.map(&:to_s)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 13])
    type = clip.infer
    expect(type.to_s).to eq('Array<String>')
  end
end
