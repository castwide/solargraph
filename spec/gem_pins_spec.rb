# frozen_string_literal: true

describe Solargraph::GemPins do
  let(:workspace) { Solargraph::Workspace.new(Dir.pwd) }
  let(:doc_map) { Solargraph::DocMap.new(requires, workspace, out: nil) }
  let(:pin) { doc_map.pins.find { |pin| pin.path == path } }

  before do
    doc_map.cache_doc_map_gems!(STDERR) # rubocop:disable Style/GlobalStdStream
  end

  context 'with a combined method pin' do
    let(:path) { 'RBS::EnvironmentLoader#core_root' }
    let(:requires) { ['rbs'] }

    it 'can merge YARD and RBS' do
      expect(pin.source).to eq(:combined)
    end

    it 'finds types from RBS' do
      expect(pin.return_type.to_s).to eq('Pathname, nil')
    end

    it 'finds locations from YARD' do
      expect(pin.location.filename).to end_with('environment_loader.rb')
    end
  end

  context 'with a YARD-only pin' do
    let(:requires) { ['rake'] }
    let(:path) { 'Rake::Task#prerequisites' }

    it 'found a pin' do
      expect(pin.source).not_to be_nil
    end

    it 'can merge YARD and RBS' do
      expect(pin.source).to eq(:yardoc)
    end

    it 'does not find types from YARD in this case' do
      expect(pin.return_type.to_s).to eq('undefined')
    end

    it 'finds locations from YARD' do
      expect(pin.location.filename).to end_with('task.rb')
    end
  end
end
