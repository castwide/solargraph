# frozen_string_literal: true

describe Solargraph::GemPins do
  it 'merges YARD and RBS' do
    spec = Gem::Specification.find_by_name('rbs')
    pins = Solargraph::GemPins.build(spec)
    core_root = pins.find { |pin| pin.path == 'RBS::EnvironmentLoader#core_root' }
    expect(core_root.return_type.to_s).to eq('Pathname, nil')
    expect(core_root.location.filename).to end_with('environment_loader.rb')
  end
end
