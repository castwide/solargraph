describe Solargraph::LanguageServer::Transport::DataReader do
  it 'rescues exceptions for invalid JSON' do
    reader = Solargraph::LanguageServer::Transport::DataReader.new
    handled = 0
    reader.set_message_handler do |_msg|
      handled += 1
    end
    msg = {
      id: 1,
      method: 'test'
    }.to_json
    msg += '}'
    expect do
      reader.receive "Content-Length:#{msg.bytesize}\r\n\r\n#{msg}"
    end.not_to raise_error
    expect(handled).to eq(0)
  end
end
