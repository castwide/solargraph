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
    expect(pins.all?{|p| [Solargraph::Pin::NAMESPACE, Solargraph::Pin::CONSTANT].include?(p.kind) }).to be(true)
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
end
