# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::Formatting do
  let(:request) do
    {
      'params' => {
        'textDocument' => {
          'uri' => 'test.rb'
        }
      }
    }
  end

  it 'gracefully handles empty files' do
    host = instance_double(Solargraph::LanguageServer::Host, read_text: '', formatter_config: {}, transformed?: false)
    message = described_class.new(host, request)
    message.process
    expect(message.process.first[:newText]).to be_empty
  end

  it 'formats Ruby files' do
    host = instance_double(Solargraph::LanguageServer::Host, read_text: "puts 'hi'  \n", formatter_config: {},
                                                             transformed?: false)
    message = described_class.new(host, request)
    message.process
    expect(message.result.first[:newText]).to eq("puts 'hi'\n")
  end

  it 'leaves sources transformed by a convention untouched' do
    host = instance_double(Solargraph::LanguageServer::Host, read_text: "puts 'hi'  \n", formatter_config: {},
                                                             transformed?: true)
    message = described_class.new(host, request)
    message.process
    expect(message.result).to eq([])
    expect(message.error).to be_nil
  end
end
