# frozen_string_literal: true

describe Solargraph::Plugin::Base do
  let(:source_map) do
    Solargraph::SourceMap.load_string(%(
      class Example
        def foo; end
      end
    ), 'test.rb')
  end
  let(:panel) { Solargraph::Plugin::Panel.new(source_maps: [source_map], live_map: source_map, gem_names: ['some_gem']) }
  let(:plugin) { described_class.new(panel) }

  describe '#pins_by_class' do
    it 'finds pins' do
      pins = plugin.pins_by_class(Solargraph::Pin::Method)
      expect(pins.map(&:path)).to eq(['Example#foo'])
    end
  end

  describe '#pins_by_path' do
    it 'finds pins' do
      pins = plugin.pins_by_path('Example#foo')
      expect(pins.map(&:path)).to eq(['Example#foo'])
    end
  end
end
