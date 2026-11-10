# frozen_string_literal: true

describe Solargraph::Collection::Gem do
  it 'types a Forwardable delegation from the gem RBS signature' do
    dir = File.expand_path('../fixtures/gem-with-delegated-rbs', __dir__)
    metagem = Solargraph::Metagem.new(name: 'gem-with-delegated-rbs', full_path: dir,
                                      spec_file: File.join(dir, 'gem-with-delegated-rbs.gemspec'),
                                      source: "source at `#{dir}`", version: '0.1.0',
                                      require_paths: ['lib'], dependencies: [])
    api_map = Solargraph::ApiMap.new(pins: described_class.new(metagem).pins)

    pin = api_map.get_method_stack('DelegatedRbs', 'name').first

    expect(pin.typify(api_map).to_s).to eq('String')
  end
end
