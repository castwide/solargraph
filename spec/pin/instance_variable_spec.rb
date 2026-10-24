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

  it 'probes ancestor ivar assignments made beyond the end of its file' do
    base = Solargraph::Source.load_string(%(
      # Ancestor whose ivar a subclass also assigns.
      class Base
        def initialize
          @foo = 'foo'
        end
      end
    ), 'base.rb')
    sub = Solargraph::Source.load_string(%(
      class Sub < Base
        def foo
          @foo
        end
        #{"\n" * 20}
        # @param value [Integer]
        def foo= value
          @foo = value
        end
      end
    ), 'sub.rb')
    api_map = Solargraph::ApiMap.new
    api_map.catalog Solargraph::Bench.new(source_maps: [base, sub].map { |s| Solargraph::SourceMap.map(s) })
    expect { api_map.clip_at('sub.rb', [3, 12]).infer }.not_to raise_error
  end
end
