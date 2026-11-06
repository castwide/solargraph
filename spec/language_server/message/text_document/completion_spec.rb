# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::Completion do
  it 'returns no items when the file is not mapped yet' do
    host = instance_double(Solargraph::LanguageServer::Host, pending_completions?: false, completions_at: nil)
    message = described_class.new(host, { 'params' => { 'textDocument' => { 'uri' => 'file:///unmapped.rb' }, 'position' => { 'line' => 0, 'character' => 0 } } })
    message.process
    expect(message.result).to eq({ isIncomplete: false, items: [] })
  end
end
