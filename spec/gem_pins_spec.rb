# frozen_string_literal: true

describe Solargraph::GemPins do
  it 'can merge YARD and RBS' do
    gemspec = Gem::Specification.find_by_name('rbs')
    yard_pins = Solargraph::GemPins.build_yard_pins([], gemspec)
    rbs_map = Solargraph::RbsMap.from_gemspec(gemspec, nil, nil)
    pins = Solargraph::GemPins.combine yard_pins, rbs_map.pins

    core_root = pins.find { |pin| pin.path == 'RBS::EnvironmentLoader#core_root' }
    expect(core_root.return_type.to_s).to eq('Pathname, nil')
    expect(core_root.location.filename).to end_with('environment_loader.rb')
  end

  it 'does not error out when handed incorrect gemspec' do
    gemspec = instance_double(Gem::Specification, name: 'foo', version: '1.0', gem_dir: '/not-there')
    expect { Solargraph::GemPins.build_yard_pins([], gemspec) }.not_to raise_error
  end
end
