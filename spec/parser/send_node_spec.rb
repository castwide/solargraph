# frozen_string_literal: true

describe Solargraph::Parser::ParserGem::NodeProcessors::SendNode do
  it 'maps a prepend with an explicit receiver' do
    map = Solargraph::SourceMap.load_string %(
      module Mixin
        def helper; end

        String.prepend(self)
      end
    )
    refs = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Prepend) }
    expect(refs.map { |ref| [ref.namespace, ref.name] }).to include(%w[String Mixin])
  end

  it 'maps an include with an explicit receiver' do
    map = Solargraph::SourceMap.load_string %(
      module Mixin
      end

      Integer.include Mixin
    )
    refs = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Include) }
    expect(refs.map { |ref| [ref.namespace, ref.name] }).to include(%w[Integer Mixin])
  end

  it 'exposes methods from a module prepended onto another class' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      module Mixin
        def helper; end

        String.prepend(self)
      end
    ), 'test.rb')
    api_map.map source
    methods = api_map.get_methods('String', scope: :instance)
    expect(methods.map(&:name)).to include('helper')
  end
end
