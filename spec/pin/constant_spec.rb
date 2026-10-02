# frozen_string_literal: true

describe Solargraph::Pin::Constant do
  it 'resolves constant paths' do
    source = Solargraph::Source.new(%(
      class Foo
        BAR = 'bar'
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select { |pin| pin.name == 'BAR' }.first
    expect(pin.path).to eq('Foo::BAR')
  end

  it 'is a constant kind' do
    source = Solargraph::Source.new(%(
      class Foo
        BAR = 'bar'
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select { |pin| pin.name == 'BAR' }.first
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CONSTANT)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::CONSTANT)
  end

  it 'resyncs the docstring :return tag, not the :type tag other variable pins use' do
    pin = described_class.new(name: 'BAR', closure: Solargraph::Pin::ROOT_PIN, comments: '@return [String]')
    realized = pin.realize(Solargraph::ApiMap.new)
    expect(realized.docstring.tag(:return).types).to eq(['::String'])
    expect(realized.docstring.tag(:type)).to be_nil
    expect(realized.return_type.rooted_tags).to eq('::String')
  end
end
