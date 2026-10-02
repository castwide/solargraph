# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::TextDocument::SignatureHelp do
  it 'sends one signature when a rooted and an unrooted spelling of one parameter type are combined, since both label the same overload' do
    namespace = Solargraph::Pin::Namespace.new(name: 'Widget', type: :class)
    rooted_pin = Solargraph::Pin::Method.new(closure: namespace, name: 'scan', scope: :instance, comments: %(
@overload scan(count)
  @param count [::Integer]
  @return [::String]
    ))
    unrooted_pin = Solargraph::Pin::Method.new(closure: namespace, name: 'scan', scope: :instance, comments: %(
@overload scan(count)
  @param count [Integer]
  @return [String]
    ))
    combined = rooted_pin.combine_with(unrooted_pin)
    convention = Class.new(Solargraph::Convention::Base) do
      define_method(:local) { |_source_map| Solargraph::Environ.new(pins: [namespace, combined]) }
    end
    Solargraph::Convention.register convention
    begin
      host = Solargraph::LanguageServer::Host.new
      host.open('file:///test.rb', 'Widget.new.scan()', 1)
      host.catalog
      message = described_class.new(host, {
                                      'params' => {
                                        'textDocument' => {
                                          'uri' => 'file:///test.rb'
                                        },
                                        'position' => {
                                          'line' => 0,
                                          'character' => 16
                                        }
                                      }
                                    })
      message.process
      expect(message.result[:signatures].map { |signature| signature[:label] }).to eq(['scan(count)'])
    ensure
      Solargraph::Convention.unregister convention
    end
  end
end
