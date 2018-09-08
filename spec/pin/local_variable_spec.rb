describe Solargraph::Pin::LocalVariable do
  it "merges presence changes" do
    map1 = Solargraph::SourceMap.load_string(%(
      class Foo
        foo = 'foo'
        @foo = foo
      end
    ))
    pin1 = map1.locals.first
    map2 = Solargraph::SourceMap.load_string(%(
      class Foo
        @more = 'more'
        foo = 'foo'
        @foo = foo
      end
    ))
    pin2 = map2.locals.first
    expect(pin1.try_merge!(pin2)).to be(true)
  end

  it "does not merge namespace changes" do
    map1 = Solargraph::SourceMap.load_string(%(
      class Foo
        foo = 'foo'
      end
    ))
    pin1 = map1.locals.first
    map2 = Solargraph::SourceMap.load_string(%(
      class Bar
        foo = 'foo'
      end
    ))
    pin2 = map2.locals.first
    expect(pin1.try_merge!(pin2)).to be(false)
  end
end
