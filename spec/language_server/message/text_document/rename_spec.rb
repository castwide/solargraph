describe Solargraph::LanguageServer::Message::TextDocument::Rename do
  it "renames a symbol" do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open('file:///file.rb', %(
      class Foo
      end
      foo = Foo.new
    ), 1)
    rename = Solargraph::LanguageServer::Message::TextDocument::Rename.new(host, {
      'id' => 1,
      'method' => 'textDocument/rename',
      'params' => {
        'textDocument' => {
          'uri' => 'file:///file.rb'
        },
        'position' => {
          'line' => 1,
          'character' => 12
        },
        'newName' => 'Bar'
      }
    })
    rename.process
    expect(rename.result[:changes]['file:///file.rb'].length).to eq(2)
  end

  it "renames an argument symbol from method signature" do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open('file:///file.rb', %(
      class Example
      def foo(bar)
      bar += 1
      return bar
      end
    	end
    	), 1)
    	rename = Solargraph::LanguageServer::Message::TextDocument::Rename.new(host, {
      'id' => 1,
      'method' => 'textDocument/rename',
      'params' => {
        'textDocument' => {
          'uri' => 'file:///file.rb'
        },
        'position' => {
          'line' => 2,
          'character' => 14
        },
        'newName' => 'baz'
      }
    })
    rename.process
    expect(rename.result[:changes]['file:///file.rb'].length).to eq(3)
  end

  it "renames an argument symbol from method body" do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open('file:///file.rb', %(
      class Example
      def foo(bar)
      bar += 1
      return bar
      end
    	end
    	), 1)
    	rename = Solargraph::LanguageServer::Message::TextDocument::Rename.new(host, {
      'id' => 1,
      'method' => 'textDocument/rename',
      'params' => {
        'textDocument' => {
          'uri' => 'file:///file.rb'
        },
        'position' => {
          'line' => 3,
          'character' => 6
        },
        'newName' => 'baz'
      }
    })
    rename.process
    expect(rename.result[:changes]['file:///file.rb'].length).to eq(3)
  end

  it "renames namespace symbol with proper range" do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open('file:///file.rb', %(
      module Namespace; end
      class Namespace::ExampleClass
      end
      obj = Namespace::ExampleClass.new
    	), 1)
    	rename = Solargraph::LanguageServer::Message::TextDocument::Rename.new(host, {
      'id' => 1,
      'method' => 'textDocument/rename',
      'params' => {
        'textDocument' => {
          'uri' => 'file:///file.rb'
        },
        'position' => {
          'line' => 2,
          'character' => 12
        },
        'newName' => 'Nameplace'
      }
    })
    rename.process
    changes = rename.result[:changes]['file:///file.rb']
    expect(changes.length).to eq(3)
    expect(changes.first[:range][:start][:character]).to eq(13)
    expect(changes.first[:range][:end][:character]).to eq(22)
  end
end
