# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::Rename do
  let(:temp_file_url) do
    # "file://#{Dir.mktmpdir}/file.rb"
    'file:///file.rb'
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
    # wait to get the result generated in a background thread, since this can be slow on CI
    timeout = Time.now + 40
    until rename.result[:changes] && rename.result[:changes][temp_file_url] && !rename.result[:changes][temp_file_url].empty?
      sleep 0.1
      if Time.now > timeout
        raise "Timed out waiting for rename result: #{rename.result.inspect}"
      end
    end

    expect(rename.result[:changes][temp_file_url]).not_to be_nil, -> { "Expected to find changes for #{temp_file_url} in #{rename.result.inspect}" }
    expect(rename.result[:changes][temp_file_url].length).to eq(3), -> { "Expected to find 3 changes for #{temp_file_url} in #{rename.result.inspect}" }
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
    # try for 20 seconds to get the result, since this can be slow on CI
    timeout = Time.now + 20
    until rename.result[:changes] && rename.result[:changes][temp_file_url] && !rename.result[:changes][temp_file_url].empty?
      sleep 0.1
      if Time.now > timeout
        raise "Timed out waiting for rename result: #{rename.result.inspect}"
      end
    end
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
    # try for 20 seconds to get the result, since this can be slow on CI
    timeout = Time.now + 20
    until rename.result[:changes] && rename.result[:changes][temp_file_url] && !rename.result[:changes][temp_file_url].empty?
      sleep 0.1
      if Time.now > timeout
        raise "Timed out waiting for rename result: #{rename.result.inspect}"
      end
    end
    changes = rename.result[:changes][temp_file_url]
    expect(changes).not_to be_nil, -> { "Expected to find changes for #{temp_file_url} in #{rename.result.inspect}" }
    expect(changes.length).to eq(3)
    expect(changes.first[:range][:start][:character]).to eq(13)
    expect(changes.first[:range][:end][:character]).to eq(22)
  end
end
