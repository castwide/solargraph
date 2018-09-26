describe Solargraph::SourceMap do
  it "locates named path pins" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
      end
    ))
    pin = map.locate_named_path_pin(2, 16)
    expect(pin.path).to eq('Foo#bar')
  end

  it "locates block pins" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        100.times do
        end
      end
    ))
    pin = map.locate_block_pin(3, 0)
    expect(pin.kind).to eq(Solargraph::Pin::BLOCK)
  end

  it "merges comment changes" do
    map1 = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
      end
    ))
    map2 = Solargraph::SourceMap.load_string(%(
      class Foo
        # My bar method
        def bar; end
      end
    ))
    expect(map1.try_merge!(map2)).to be(true)
  end

  it "merges require equivalents" do
    map1 = Solargraph::SourceMap.load_string("require 'foo'")
    map2 = Solargraph::SourceMap.load_string("require 'foo' # Insignificant comment")
    expect(map1.try_merge!(map2)).to be(true)
  end

  it "does not merge require changes" do
    map1 = Solargraph::SourceMap.load_string("require 'foo'")
    map2 = Solargraph::SourceMap.load_string("require 'bar'")
    expect(map1.try_merge!(map2)).to be(false)
  end

  # @todo This test might not be legitimate anymore. Since requires references
  #   are now proper pins, changing the order invalidates the merge.
  it "merges reordered requires" do
    # map1 = Solargraph::SourceMap.load_string("require 'foo'; require 'bar'")
    # map2 = Solargraph::SourceMap.load_string("require 'bar'; require 'foo'")
    # expect(map1.try_merge!(map2)).to be(true)
  end

  it "merges repaired changes" do
    source1 = Solargraph::Source.load_string(%(
      list.each do |item|
       i
      end
    ))
    updater = Solargraph::Source::Updater.new(
      nil,
      2,
      [
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(2, 8, 2, 8),
          'f '
        )
      ]
    )
    source2 = source1.synchronize(updater)
    map1 = Solargraph::SourceMap.map(source1)
    pos1 = Solargraph::Position.new(2, 8)
    pin1 = map1.pins.select{|p| p.location.range.contain?(pos1)}.first
    map2 = Solargraph::SourceMap.map(source2)
    expect(map1.try_merge!(map2)).to be(true)
    pos2 = Solargraph::Position.new(2, 10)
    pin2 = map1.pins.select{|p| p.location.range.contain?(pos2)}.first
    expect(pin1).to eq(pin2)
  end
end
