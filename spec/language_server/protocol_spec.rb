require 'thread'

class Protocol
  attr_reader :response

  # @return [Solargraph::LanguageServer::Host]
  attr_reader :host

  def initialize host
    @host = host
    @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
    @data_reader.set_message_handler do |message|
      @response = message
    end
    @message_id = 0
  end

  def request method, params
    @response = nil
    msg = {
      'id' => @message_id,
      'method' => method,
      'params' => params
    }
    @message_id += 1
    message = @host.start msg
    message.send_response
    @data_reader.receive @host.flush
  end
end

describe Protocol do
  before :all do
    @protocol = Protocol.new(Solargraph::LanguageServer::Host.new)
  end

  it "handles initialize" do
    @protocol.request 'initialize', {}
    response = @protocol.response
    expect(response['result'].keys).to include('capabilities')
  end

  it "handles initialized" do
    @protocol.request 'initialized', nil
    response = @protocol.response
    expect(response['error']).to be_nil
  end

  it "handles textDocument/didOpen" do
    @protocol.request 'textDocument/didOpen', {
      'textDocument' => {
        'uri' => 'file:///file.rb',
        'text' => %(
          class Foo
            def bar baz
            end
          end
          foo = Foo.new
          String
          foo.bar()
        ),
        'version' => 0
      }
    }
    response = @protocol.response
    expect(@protocol.host.open?('file:///file.rb')).to be(true)
  end

  it "handles textDocument/didChange" do
    @protocol.request 'textDocument/didChange', {
      'textDocument' => {
        'uri' => 'file:///file.rb',
        'version' => 1
      },
      'contentChanges' => [
        {
          'range' => {
            'start' => {
              'line' => 6,
              'character' => 16
            },
            'end' => {
              'line' => 6,
              'character' => 16
            }
          },
          'text' => ';'
        }
      ]
    }
    response = @protocol.response
    # @todo What to expect?
  end

  it "handles textDocument/completion" do
    @protocol.request 'textDocument/completion', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      },
      'position' => {
        'line' => 0,
        'character' => 7
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']['items'].length > 0).to be(true)
  end

  it "handles workspace/symbol" do
    @protocol.request 'workspace/symbol', {
      'query' => 'test'
    }
    response = @protocol.response
    expect(response['error']).to be_nil
  end

  it "handles textDocument/definition" do
    @protocol.request 'textDocument/definition', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      },
      'position' => {
        'line' => 5,
        'character' => 17
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']).not_to be_nil
  end

  it "handles completionItem/resolve" do
    @protocol.request 'textDocument/completion', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      },
      'position' => {
        'line' => 6,
        'character' => 12
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    item = response['result']['items'].select{|item| item['label'] == 'String' and item['kind'] == Solargraph::LanguageServer::CompletionItemKinds::CLASS}.first
    expect(item).not_to be_nil
    @protocol.request 'completionItem/resolve', item
    response = @protocol.response
    expect(response['result']['documentation']).not_to be_nil
    expect(response['result']['documentation']).not_to be_empty
  end

  it "handles textDocument/documentSymbol" do
    @protocol.request 'textDocument/documentSymbol', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
  end

  it "handles textDocument/hover" do
    @protocol.request 'textDocument/hover', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      },
      'position' => {
        'line' => 5,
        'character' => 17
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    # Given this request hovers over `Foo`, the result should not be empty
    expect(response['result']['contents']).not_to be_empty
  end

  it "handles textDocument/signatureHelp" do
    @protocol.request 'textDocument/signatureHelp', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      },
      'position' => {
        'line' => 7,
        'character' => 18
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']['signatures']).not_to be_empty
  end

  it "handles workspace/symbol" do
    @protocol.request 'workspace/symbol', {
      'query' => 'Foo'
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']).not_to be_empty
  end

  it "handles textDocument/didClose" do
    @protocol.request 'textDocument/didClose', {
      'textDocument' => {
        'uri' => 'file:///file.rb'
      }
    }
    response = @protocol.response
    expect(@protocol.host.open?('file:///file.rb')).to be(false)
  end

  it "handles $/solargraph/search" do
    @protocol.request '$/solargraph/search', {
      'query' => 'Foo#bar'
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']['content']).not_to be_empty
  end

  it "handles $/solargraph/document" do
    @protocol.request '$/solargraph/document', {
      'query' => 'String'
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']['content']).not_to be_empty
  end

  it "handles workspace/didChangeConfiguration" do
    @protocol.request 'workspace/didChangeConfiguration', {
      'settings' => {
        'solargraph' => {
          'autoformat' => false
        }
      }
    }
    expect(@protocol.host.options['autoformat']).to be(false)
  end

  it "handles $/solargraph/checkGemVersion" do
    @protocol.request '$/solargraph/checkGemVersion', { verbose: false }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result']['installed']).to be_a(String)
    expect(response['result']['available']).to be_a(String)
  end

  it "handles $/solargraph/documentGems" do
    @protocol.request '$/solargraph/documentGems', {}
    response = @protocol.response
    expect(response['error']).to be_nil
  end

  it "handles textDocument/formatting" do
    @protocol.request 'textDocument/formatting', {
      'textDocument' => {
        'uri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(File.realpath('spec/fixtures/formattable.rb'))
      }
    }
    response = @protocol.response
    expect(response['error']).to be_nil
    expect(response['result'].first['newText']).to be_a(String)
  end
end
