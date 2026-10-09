# frozen_string_literal: true

require 'pry'

describe Solargraph::Pin::DelegatedMethod do
  it 'can be constructed from a Method pin' do
    method_pin = Solargraph::Pin::Method.new(comments: '@return [Hash{String => String}]')

    delegation_pin = described_class.new(method: method_pin, scope: :instance)
    expect(delegation_pin.return_type.to_s).to eq('Hash{String => String}')
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

  it 'resolves a class method when the receiver is the class' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Class1
        # @return [String]
        def self.label; end
      end
    ))
    api_map.map source

    class1 = api_map.get_path_pins('Class1').first

    # delegate :label, to: :class
    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('class', nil)])
    pin = described_class.new(
      closure: class1,
      scope: :instance,
      name: 'label',
      receiver: chain
    )

    pin.probe(api_map)

    expect(pin.return_type.to_s).to eq('String')
  end

  context 'with a constant receiver' do
    let(:api_map) { Solargraph::ApiMap.new }

    before do
      api_map.map Solargraph::Source.load_string(%(
        class Class1
          # @return [String]
          def self.label; end
        end

        module Mod
          # @return [Integer]
          def self.label; end
        end

        class Conf
          # @return [Symbol]
          def label; end
        end

        # @return [Conf]
        CONF = Conf.new
      ))
    end

    # @param constant [String]
    # @return [String]
    def delegated_label_type constant
      chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Constant.new(constant)])
      pin = described_class.new(closure: api_map.get_path_pins('Class1').first, scope: :instance, name: 'label',
                                receiver: chain)
      pin.probe(api_map)
      pin.return_type.to_s
    end

    it 'resolves the class method of a class' do
      expect(delegated_label_type('Class1')).to eq('String')
    end

    it 'resolves the singleton method of a module' do
      expect(delegated_label_type('Mod')).to eq('Integer')
    end

    it 'resolves the instance method of an object a constant holds' do
      expect(delegated_label_type('CONF')).to eq('Symbol')
    end
  end
end
