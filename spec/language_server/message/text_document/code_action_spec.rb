# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::CodeAction do
  let(:host) { instance_double(Solargraph::LanguageServer::Host) }
  let(:uri) { 'file:///project/spec/thing_spec.rb' }
  let(:lenses) do
    [0, 4].map do |line|
      Solargraph::CodeLens.new(
        range: Solargraph::Range.from_to(line, 0, line, 0),
        command: Solargraph::Command.new(title: "Run #{line}", command: 'solargraph.runRspec',
                                         arguments: [{ command: "rspec spec/thing_spec.rb:#{line + 1}" }])
      )
    end
  end

  before do
    allow(host).to receive(:code_lenses).with(uri).and_return(lenses)
  end

  # @param start_line [Integer]
  # @param end_line [Integer]
  # @param only [Array<String>, nil]
  def process_message start_line, end_line, only: nil
    context = { 'diagnostics' => [] }
    context['only'] = only if only
    message = described_class.new(host, {
                                    'params' => {
                                      'textDocument' => { 'uri' => uri },
                                      'range' => {
                                        'start' => { 'line' => start_line, 'character' => 0 },
                                        'end' => { 'line' => end_line, 'character' => 0 }
                                      },
                                      'context' => context
                                    }
                                  })
    message.process
    message.result
  end

  it 'offers the code lenses on the requested lines as source actions' do
    expect(process_message(0, 0)).to eq([
                                          {
                                            title: 'Run 0',
                                            kind: 'source',
                                            command: {
                                              title: 'Run 0',
                                              command: 'solargraph.runRspec',
                                              arguments: [{ command: 'rspec spec/thing_spec.rb:1' }]
                                            }
                                          }
                                        ])
  end

  it 'includes every code lens within the range' do
    expect(process_message(0, 10).map { |action| action[:title] }).to eq(['Run 0', 'Run 4'])
  end

  it 'returns nothing on lines without code lenses' do
    expect(process_message(1, 3)).to eq([])
  end

  it 'returns nothing when the client only asks for other kinds' do
    expect(process_message(0, 0, only: ['quickfix'])).to eq([])
  end

  it 'returns the actions when the client asks for source actions' do
    expect(process_message(0, 0, only: ['source']).size).to eq(1)
  end
end
