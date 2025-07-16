# frozen_string_literal: true

describe Solargraph::GemPins do
  it 'can merge YARD and RBS' do
    workspace = Solargraph::Workspace.new(Dir.pwd)
    doc_map = Solargraph::DocMap.new(['rbs'], workspace)
    doc_map.cache_doc_map_gems!($stderr)

    core_root = doc_map.pins.find { |pin| pin.path == 'RBS::EnvironmentLoader#core_root' }
    expect(core_root.return_type.to_s).to eq('Pathname, nil')
    expect(core_root.location.filename).to end_with('environment_loader.rb')
  end
end
