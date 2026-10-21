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

  describe '#addon' do
    it 'adds nothing by default' do
      expect(plugin.addon).to be(Solargraph::Plugin::EMPTY_ADDON)
    end
  end

  describe 'registration' do
    let(:failing_plugin) do
      Class.new(described_class) do
        def addon
          raise 'broken plugin'
        end
      end
    end

    after { Solargraph::Plugin.unregister failing_plugin }

    it 'catalogs an ApiMap when a registered plugin raises' do
      Solargraph::Plugin.register failing_plugin
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string('class Example; end', 'test.rb'))
      expect(api_map.get_path_pins('Example')).not_to be_empty
    end

    it 'unregisters plugins' do
      Solargraph::Plugin.register failing_plugin
      Solargraph::Plugin.unregister failing_plugin
      expect(Solargraph::Plugin.registry).not_to include(failing_plugin)
    end
  end

  describe '#pins_by_path' do
    it 'finds pins' do
      pins = plugin.pins_by_path('Example#foo')
      expect(pins.map(&:path)).to eq(['Example#foo'])
    end
  end
end
