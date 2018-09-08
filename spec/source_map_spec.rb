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
end
