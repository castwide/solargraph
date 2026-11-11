# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::CodeLens do
  let(:host) { instance_double(Solargraph::LanguageServer::Host) }
  let(:uri) { 'file:///project/spec/thing_spec.rb' }
  let(:lens) do
    Solargraph::CodeLens.new(
      range: Solargraph::Range.from_to(2, 0, 2, 0),
      command: Solargraph::Command.new(title: 'Run', command: 'solargraph.runRspec',
                                       arguments: [{ command: 'rspec spec/thing_spec.rb:3' }])
    )
  end

  it 'returns the code lenses of the document' do
    allow(host).to receive(:code_lenses).with(uri).and_return([lens])
    message = described_class.new(host, { 'params' => { 'textDocument' => { 'uri' => uri } } })
    message.process

    expect(message.result).to eq([
                                   {
                                     range: { start: { line: 2, character: 0 }, end: { line: 2, character: 0 } },
                                     command: {
                                       title: 'Run',
                                       command: 'solargraph.runRspec',
                                       arguments: [{ command: 'rspec spec/thing_spec.rb:3' }]
                                     }
                                   }
                                 ])
  end
end
