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

  context 'with a Forwardable delegation' do
    let(:api_map) do
      source = Solargraph::Source.load_string(%(
        require 'forwardable'

        class Inner
          # Counts the widgets.
          # @return [Integer]
          def count_widgets; 1; end
        end

        class Outer
          extend Forwardable
          def_delegator :inner, :count_widgets

          # @return [Inner]
          def inner; Inner.new; end
        end

        Outer.new.count_widgets
      ), 'test.rb')
      Solargraph::ApiMap.new.tap { |map| map.map source }
    end

    let(:clip) { api_map.clip_at('test.rb', [17, 20]) }

    it 'documents the delegation with the target method docs' do
      expect(clip.define.first.documentation).to include('Counts the widgets.')
    end

    it 'documents the delegation after completion read its docs' do
      clip.complete.pins.find { |pin| pin.name == 'count_widgets' }.documentation

      expect(clip.define.first.documentation).to include('Counts the widgets.')
    end
  end
end
