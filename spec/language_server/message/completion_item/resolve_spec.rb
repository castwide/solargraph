# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::CompletionItem::Resolve do
  it 'returns MarkupContent for documentation' do
    pin = Solargraph::Pin::Method.new(
      location: nil,
      closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
      name: 'bar',
      comments: 'A method',
      scope: :instance,
      visibility: :public,
      parameters: []
    )
    host = instance_double(Solargraph::LanguageServer::Host, locate_pins: [pin], options: { 'enablePages' => true })
    resolve = described_class.new(host, {
                                    'params' => pin.completion_item
                                  })
    resolve.process
    expect(resolve.result[:documentation][:kind]).to eq('markdown')
    expect(resolve.result[:documentation][:value]).to include('A method')
  end

  it 'returns nil documentation for empty strings' do
    pin = Solargraph::Pin::InstanceVariable.new(
      location: nil,
      closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
      name: '@bar',
      comments: ''
    )
    host = instance_double(Solargraph::LanguageServer::Host, locate_pins: [pin])
    resolve = described_class.new(host, {
                                    'params' => pin.completion_item
                                  })
    resolve.process
    expect(resolve.result[:documentation]).to be_nil
  end

  it 'preserves label and kind when resolving a keyword argument completion' do
    code = "class Example\n  def call(long_keyword_argument_name: \"\")\n  end\nend\n\nExample.new.call(long_keyword_arg)"
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open 'file:///example.rb', code, 1
    sleep 1
    completion = host.completions_at('file:///example.rb', 5, 33)
    pin = completion.pins.find { |p| p.name == 'long_keyword_argument_name:' }
    expect(pin).not_to be_nil
    item = pin.completion_item
    item[:data][:uri] = 'file:///example.rb'
    resolve = described_class.new(host, { 'params' => JSON.parse(JSON.generate(item)) })
    resolve.process
    expect(resolve.result[:label]).to eq('long_keyword_argument_name:')
    expect(resolve.result[:kind]).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
  end

  it 'does not modify immutable properties during resolve' do
    resolved_pin = Solargraph::Pin::Namespace.new(name: '')
    host = instance_double(Solargraph::LanguageServer::Host, locate_pins: [resolved_pin], options: { 'enablePages' => true })
    params = Solargraph::Pin::Method.new(
      location: nil,
      closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
      name: 'bar',
      comments: 'A method',
      scope: :instance,
      visibility: :public,
      parameters: []
    ).completion_item.merge(
      sortText: '0001bar',
      filterText: 'bar',
      insertText: 'bar()',
      textEdit: { range: { start: { line: 0, character: 0 }, end: { line: 0, character: 3 } }, newText: 'bar' }
    )
    resolve = described_class.new(host, { 'params' => JSON.parse(JSON.generate(params)) })
    resolve.process
    stringify = ->(obj) {
      case obj
      when Hash then obj.transform_keys(&:to_s).transform_values { |v| stringify.call(v) }
      when Array then obj.map { |v| stringify.call(v) }
      else obj
      end
    }
    %w[label kind sortText filterText insertText textEdit data].each do |field|
      expect(stringify.call(resolve.result[field.to_sym])).to eq(stringify.call(params[field.to_sym]))
    end
  end
end
