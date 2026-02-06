# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::Rename do
  before :context do
    @temp_file_url = "file:///#{Dir.mktmpdir}/file.rb"
  end

  let(:temp_file_url) do
    @temp_file_url
  end

  it 'renames a symbol' do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open(temp_file_url, %(
      class Foo
      end
      foo = Foo.new
    ), 1)
    sleep 0.01 until host.libraries.all?(&:mapped?)
    rename = described_class.new(host, {
                                   'id' => 1,
                                   'method' => 'textDocument/rename',
                                   'params' => {
                                     'textDocument' => {
                                       'uri' => temp_file_url
                                     },
                                     'position' => {
                                       'line' => 1,
                                       'character' => 12
                                     },
                                     'newName' => 'Bar'
                                   }
                                 })
    # keep this from syncing a bunch of bundle gems in background
    library = host.library_for(temp_file_url)
    allow(library).to receive(:cacheable_specs).and_return([])
    rename.process
    expect(rename.result[:changes][temp_file_url].length).to eq(2)
  end

  it 'renames an argument symbol from method signature' do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open(temp_file_url, %(
      class Example
      def foo(bar)
      bar += 1
      return bar
      end
    	end

    ), 1)
    # keep this from syncing a bunch of bundle gems in background
    library = host.library_for(temp_file_url)
    allow(library).to receive(:cacheable_specs).and_return([])
    rename = described_class.new(host, {
                                   'id' => 1,
                                   'method' => 'textDocument/rename',
                                   'params' => {
                                     'textDocument' => {
                                       'uri' => temp_file_url
                                     },
                                     'position' => {
                                       'line' => 2,
                                       'character' => 14
                                     },
                                     'newName' => 'baz'
                                   }
                                 })
    rename.process
    expect(rename.result[:changes][temp_file_url].length).to eq(3)
  end

  it 'renames an argument symbol from method body' do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open(temp_file_url, %(
      class Example
      def foo(bar)
      bar += 1
      return bar
      end
    	end
    ), 1)
    rename = described_class.new(host, {
                                   'id' => 1,
                                   'method' => 'textDocument/rename',
                                   'params' => {
                                     'textDocument' => {
                                       'uri' => temp_file_url
                                     },
                                     'position' => {
                                       'line' => 3,
                                       'character' => 6
                                     },
                                     'newName' => 'baz'
                                   }
                                 })
    # keep this from syncing a bunch of bundle gems in background
    library = host.library_for(temp_file_url)
    allow(library).to receive(:cacheable_specs).and_return([])
    rename.process
    expect(rename.result[:changes][temp_file_url].length).to eq(3)
  end

  it 'renames namespace symbol with proper range' do
    host = Solargraph::LanguageServer::Host.new
    host.start
    host.open(temp_file_url, %(
      module Namespace; end
      class Namespace::ExampleClass
      end
      obj = Namespace::ExampleClass.new
    ), 1)
    rename = described_class.new(host, {
                                   'id' => 1,
                                   'method' => 'textDocument/rename',
                                   'params' => {
                                     'textDocument' => {
                                       'uri' => temp_file_url
                                     },
                                     'position' => {
                                       'line' => 2,
                                       'character' => 12
                                     },
                                     'newName' => 'Nameplace'
                                   }
                                 })
    # keep this from syncing a bunch of bundle gems in background
    library = host.library_for(temp_file_url)
    allow(library).to receive(:cacheable_specs).and_return([])
    rename.process
    changes = rename.result[:changes][temp_file_url]
    expect(changes).not_to be_nil, -> { "Expected to find changes for #{temp_file_url} in #{rename.result.inspect}" }
    expect(changes.length).to eq(3)
    expect(changes.first[:range][:start][:character]).to eq(13)
    expect(changes.first[:range][:end][:character]).to eq(22)
  end
end
