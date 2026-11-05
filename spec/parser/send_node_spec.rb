# frozen_string_literal: true

describe Solargraph::Parser::ParserGem::NodeProcessors::SendNode do
  # @param namespace [String]
  # @param code [String]
  # @return [Array<Solargraph::Pin::Method>]
  def method_pins_for namespace, code
    Solargraph::SourceMap.load_string(code).pins.select do |pin|
      pin.is_a?(Solargraph::Pin::Method) && pin.namespace == namespace
    end
  end

  # @return [Array<Array(String, Symbol)>]
  def accessors pins
    pins.map { |pin| [pin.name, pin.context.scope] }.sort
  end

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
