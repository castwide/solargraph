describe Solargraph::SourceMap::Clip do
  let(:api_map) { Solargraph::ApiMap.new }

  it "completes constants" do
    source = Solargraph::Source.load_string('File::')
    api_map.catalog [source]
    cursor = source.cursor_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:path)).to include('File::SEPARATOR')
  end

  it "completes class variables" do
    source = Solargraph::Source.load_string('@@foo = 1; @@f', 'test.rb')
    api_map.catalog [source]
    cursor = source.cursor_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@@foo')
  end

  it "completes instance variables" do
    source = Solargraph::Source.load_string('@foo = 1; @f', 'test.rb')
    api_map.catalog [source]
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@foo')
  end

  it "completes global variables" do
    source = Solargraph::Source.load_string('$foo = 1; $f', 'test.rb')
    api_map.catalog [source]
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 11))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('$foo')
  end

  it "completes symbols" do
    source = Solargraph::Source.load_string('$foo = :foo; :f', 'test.rb')
    api_map.catalog [source]
    clip = api_map.clip_at('test.rb', Solargraph::Position.new(0, 15))
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include(':foo')
  end

  it "completes core constants and methods" do
    source = Solargraph::Source.load_string('')
    api_map.catalog [source]
    cursor = source.cursor_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, cursor)
    comp = clip.complete
    paths = comp.pins.map(&:path)
    expect(paths).to include('String')
    expect(paths).to include('Kernel#puts')
  end

  it "defines core constants" do
    source = Solargraph::Source.load_string('String')
    api_map.catalog [source]
    cursor = source.cursor_at(Solargraph::Position.new(0, 0))
    clip = described_class.new(api_map, cursor)
    pins = clip.define
    expect(pins.map(&:path)).to include('String')
  end

  it "signifies core methods" do
    source = Solargraph::Source.load_string('File.dirname()')
    api_map.catalog [source]
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
    api_map.catalog [source]
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
    api_map.catalog [source]
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
    api_map.catalog [source]
    cursor = source.cursor_at(Solargraph::Position.new(3, 0))
    clip = described_class.new(api_map, cursor)
    expect(clip.locals.map(&:name)).not_to include('z')
  end
end
