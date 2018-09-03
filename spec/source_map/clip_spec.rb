describe Solargraph::SourceMap::Clip do
  let(:api_map) { Solargraph::ApiMap.new }

  it "completes constants" do
    map = Solargraph::SourceMap.load_string('File::')
    fragment = map.fragment_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    expect(comp.pins.map(&:path)).to include('File::SEPARATOR')
  end

  it "completes class variables" do
    source = Solargraph::Source.load_string('@@foo = 1; @@f', 'test.rb')
    api_map.replace source
    fragment = api_map.fragment_at('test.rb', Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@@foo')
  end

  it "completes instance variables" do
    source = Solargraph::Source.load_string('@foo = 1; @f', 'test.rb')
    api_map.replace source
    fragment = api_map.fragment_at('test.rb', Solargraph::Position.new(0, 11))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('@foo')
  end

  it "completes global variables" do
    source = Solargraph::Source.load_string('$foo = 1; $f', 'test.rb')
    api_map.replace source
    fragment = api_map.fragment_at('test.rb', Solargraph::Position.new(0, 11))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include('$foo')
  end

  it "completes symbols" do
    source = Solargraph::Source.load_string('$foo = :foo; :f', 'test.rb')
    api_map.replace source
    fragment = api_map.fragment_at('test.rb', Solargraph::Position.new(0, 15))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    expect(comp.pins.map(&:name)).to include(':foo')
  end

  it "completes core constants and methods" do
    map = Solargraph::SourceMap.load_string('')
    fragment = map.fragment_at(Solargraph::Position.new(0, 6))
    clip = described_class.new(api_map, fragment)
    comp = clip.complete
    paths = comp.pins.map(&:path)
    expect(paths).to include('String')
    expect(paths).to include('Kernel#puts')
  end

  it "defines core constants" do
    map = Solargraph::SourceMap.load_string('String')
    fragment = map.fragment_at(Solargraph::Position.new(0, 0))
    clip = described_class.new(api_map, fragment)
    pins = clip.define
    expect(pins.map(&:path)).to include('String')
  end

  it "signifies core methods" do
    map = Solargraph::SourceMap.load_string('File.dirname()')
    fragment = map.fragment_at(Solargraph::Position.new(0, 13))
    clip = described_class.new(api_map, fragment)
    pins = clip.signify
    expect(pins.map(&:path)).to include('File.dirname')
  end
end
