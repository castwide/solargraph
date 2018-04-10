require 'thread'

class Protocol
  attr_reader :response

  def initialize host
    @host = host
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
    message.send
    open @host.flush
  end

  private

  def open envelope
    if envelope.nil?
      @response = nil
    else
      header, content = envelope.split("\r\n\r\n")
      @response = JSON.parse(content)
    end
  end
end

describe Protocol do
  before :all do
    @protocol = Protocol.new(Solargraph::LanguageServer::Host.new)
  end

  it "handles initialize" do
    @protocol.request 'initialize', {
      'rootPath' => nil,
      'initializationOptions' => {}
    }
    response = @protocol.response
    expect(response['result'].keys).to include('capabilities')
  end

  it "handles textDocument/didOpen" do
    @protocol.request 'textDocument/didOpen', {
      'textDocument' => {
        'uri' => 'file:///file.rb',
        'text' => %(
          class Foo
            def bar
            end
          end
          foo = Foo
          String
        ),
        'version' => 0
      }
    }
    response = @protocol.response
    # @todo What to expect?
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
              'line' => 5,
              'character' => 19
            },
            'end' => {
              'line' => 5,
              'character' => 19
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
end
