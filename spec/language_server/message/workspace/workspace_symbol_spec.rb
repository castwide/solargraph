# frozen_string_literal: true

require 'timeout'

describe Solargraph::LanguageServer::Message::Workspace::WorkspaceSymbol do
  let(:convention) do
    Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: [
            Solargraph::Pin::Method.new(
              closure: Solargraph::Pin::Namespace.new(name: 'FooBar', type: :class),
              name: 'baz_convention',
              scope: :instance
            )
          ]
        )
      end
    end
  end

  before { Solargraph::Convention.register convention }

  after { Solargraph::Convention.unregister convention }

  it 'skips convention pins without a location' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'foo_bar.rb'), "class FooBar\n  def baz_real; end\nend\n")
      host = Solargraph::LanguageServer::Host.new
      host.prepare(dir)
      Timeout.timeout 60 do
        sleep 0.1 until host.libraries.all?(&:mapped?)
      end
      host.catalog
      message = described_class.new(host, { 'params' => { 'query' => 'baz' } })
      message.process
      names = message.result.map { |info| info[:name] }
      expect(names).to include('FooBar#baz_real')
      expect(names).not_to include('FooBar#baz_convention')
    end
  end
end
