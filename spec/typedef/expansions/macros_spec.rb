# frozen_string_literal: true

describe Solargraph::Typedef::Expansions::Macros do
  it 'expands named macros' do
    source = Solargraph::Source.load_string(%(
      # @!macro [new] klassify
      #   @return [Array<$1>]
      class Example
        # @macro klassify
        def foo(klass)
        end  
      end
    ))
    api_map = Solargraph::ApiMap.new.map(source)
    pin = api_map.get_path_pins('Example#foo').first
    typeset = described_class.expand(api_map, pin, nil)
    expect(typeset.to_s).to eq('Array[klass]')
  end
end
