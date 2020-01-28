describe 'Node processor (generic)' do
  it 'maps arg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(arg); end
      end
    ))
    expect(map.locals.first.decl).to eq(:arg)
  end

  it 'maps optarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(arg = 0); end
      end
    ))
    expect(map.locals.first.decl).to eq(:optarg)
  end

  it 'maps kwarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(arg:); end
      end
    ))
    expect(map.locals.first.decl).to eq(:kwarg)
  end

  it 'maps kwoptarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(arg: 0); end
      end
    ))
    expect(map.locals.first.decl).to eq(:kwoptarg)
  end

  it 'maps restarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(*arg); end
      end
    ))
    expect(map.locals.first.decl).to eq(:restarg)
  end

  it 'maps kwrestarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(**arg); end
      end
    ))
    expect(map.locals.first.decl).to eq(:kwrestarg)
  end

  it 'maps blockarg parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(&arg); end
      end
    ))
    expect(map.locals.first.decl).to eq(:blockarg)
  end
end
