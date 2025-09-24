describe Solargraph::Pin::LocalVariable do
  xit 'merges presence changes so that [not currently used]' do
    map1 = Solargraph::SourceMap.load_string(%(
      class Foo
        foo = 'foo'
        @foo = foo
      end
    ))
    pin1 = map1.locals.first
    expect(pin1.presence.start.to_hash).to eq({ line: 2, character: 8 })
    expect(pin1.presence.ending.to_hash).to eq({ line: 4, character: 9 })

    map2 = Solargraph::SourceMap.load_string(%(
      class Foo
        @more = 'more'
        foo = 'foo'
        @foo = foo
      end
    ))
    pin2 = map2.locals.first
    expect(pin2.presence.start.to_hash).to eq({ line: 3, character: 8 })
    expect(pin2.presence.ending.to_hash).to eq({ line: 5, character: 9 })

    combined = pin1.combine_with(pin2)
    expect(combined).to be_a(Solargraph::Pin::LocalVariable)

    expect(combined.source).to eq(:combined)
    # no choice behavior defined yet - if/when this is to be used, we
    # should indicate which one should override in the range situation
  end

  it 'asserts on attempt to merge namespace changes' do
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
    # set env variable 'FOO' to 'true' in block

    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect(Solargraph.asserts_on?(:combine_with_closure_name)).to be true
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :closure name/)
    end
  end
end
