describe Solargraph::RbsMap do
  it 'loads from a gemspec' do
    spec = Gem::Specification.find_by_name('rbs')
    rbs_map = Solargraph::RbsMap.from_gemspec(spec)
    pin = rbs_map.path_pin('RBS::EnvironmentLoader.new')
    expect(pin).to be
  end
end
