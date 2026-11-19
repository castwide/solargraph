# frozen_string_literal: true

require 'pry'

describe Solargraph::Pin::DelegatedMethod do
  it 'can be constructed from a Method pin' do
    method_pin = Solargraph::Pin::Method.new(comments: '@return [Hash{String => String}]')

    delegation_pin = described_class.new(method: method_pin, scope: :instance)
    expect(delegation_pin.return_type.to_s).to eq('Hash{String => String}')
  end

  it 'requires a name when constructed from a receiver source' do
    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('collaborator', nil)])

    expect do
      described_class.new(receiver: chain, receiver_method_name: 'name', scope: :instance)
    end.to raise_error(ArgumentError)
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
    pin = described_class.new(
      closure: class2,
      scope: :instance,
      name: 'name',
      receiver: chain
    )

    pin.probe(api_map)

    expect(pin.return_type.to_s).to eq('String')
  end

  it 'resolves a class method on a constant receiver' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Class1
        # @return [String]
        def self.make; end
      end

      class Class2; end
    ))
    api_map.map source

    class2 = api_map.get_path_pins('Class2').first

    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Constant.new('Class1')])
    pin = described_class.new(
      closure: class2,
      scope: :class,
      name: 'make',
      receiver: chain
    )

    expect(pin.resolvable?(api_map)).to be(true)
    expect(pin.return_type.to_s).to eq('String')
  end

  it 'is not resolvable when its receiver cannot be resolved' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Class2; end
    ))
    api_map.map source

    class2 = api_map.get_path_pins('Class2').first

    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('missing_collaborator', nil)])
    pin = described_class.new(
      closure: class2,
      scope: :instance,
      name: 'name',
      receiver: chain
    )

    expect(pin.resolvable?(api_map)).to be(false)
  end
end
