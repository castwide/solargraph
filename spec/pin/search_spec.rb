describe Solargraph::Pin::Search do
  it 'returns ordered matches on paths' do
    example_class = Solargraph::Pin::Namespace.new(name: 'Example')
    pins = [
      example_class,
      Solargraph::Pin::Method.new(name: 'foobar', closure: example_class),
      Solargraph::Pin::Method.new(name: 'foo_bar', closure: example_class)
    ]
    search = Solargraph::Pin::Search.new(pins, 'example')
    expect(search.results).to eq(pins)
  end

  it 'returns ordered matches on names' do
    example_class = Solargraph::Pin::Namespace.new(name: 'Example')
    pins = [
      example_class,
      Solargraph::Pin::Method.new(name: 'foobar', closure: example_class),
      Solargraph::Pin::Method.new(name: 'foo_bar', closure: example_class)
    ]
    search = Solargraph::Pin::Search.new(pins, 'foobar')
    expect(search.results.map(&:path)).to eq(['Example.foobar', 'Example.foo_bar'])
  end

  it 'filters insufficient matches' do
    example_class = Solargraph::Pin::Namespace.new(name: 'Example')
    pins = [
      example_class,
      Solargraph::Pin::Method.new(name: 'foobar', closure: example_class),
      Solargraph::Pin::Method.new(name: 'bazquz', closure: example_class)
    ]
    search = Solargraph::Pin::Search.new(pins, 'foobar')
    expect(search.results.map(&:path)).to eq(['Example.foobar'])
  end
end
