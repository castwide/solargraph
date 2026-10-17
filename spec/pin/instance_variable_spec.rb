# frozen_string_literal: true

describe Solargraph::Pin::InstanceVariable do
  it 'is a kind of variable' do
    source = Solargraph::Source.load_string("@foo = 'foo'", 'file.rb')
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select { |p| p.is_a?(described_class) }.first
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::VARIABLE)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::VARIABLE)
  end

  it 'does not link documentation for undefined return types' do
    pin = described_class.new(name: '@bar')
    expect(pin.link_documentation).to eq('@bar')
  end

  it 'does not dominate reads from a block outside its closure' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
          @x = 1
          @x
        end
      end
    ), 'test.rb')
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.find { |p| p.is_a?(described_class) }
    read = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(4, 10, 4, 12))
    orphan_block = Solargraph::Pin::Block.new(closure: nil)
    expect(pin.dominates?(pin.closure, read)).to be(true)
    expect(pin.dominates?(orphan_block, read)).to be(false)
  end
end
