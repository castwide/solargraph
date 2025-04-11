require 'pry'

describe Solargraph::Pin::DelegatedMethod do
  it 'can be constructed from a Method pin' do
    method_pin = Solargraph::Pin::Method.new(comments: '@return [Hash<String, String>]')

    delegation_pin = Solargraph::Pin::DelegatedMethod.new(method: method_pin, scope: :instance)
    expect(delegation_pin.return_type.to_s).to eq('Hash<String, String>')
  end

  it 'can be constructed from a receiver source and method name' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Class1
        # @return [String]
        def name; end
      end

      class Class2
        # @return [Class1]
        def collaborator; end
      end
    ))
    api_map.map source

    class2 = api_map.get_path_pins('Class2').first

    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('collaborator', nil)])
    pin = Solargraph::Pin::DelegatedMethod.new(
      closure: class2,
      scope: :instance,
      name: 'name',
      receiver: chain
    )

    pin.probe(api_map)

    expect(pin.return_type.to_s).to eq('String')
  end
end
