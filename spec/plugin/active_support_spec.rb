# frozen_string_literal: true

describe Solargraph::Plugin::ActiveSupport do
  let(:source) do
    Solargraph::Source.load_string(%(
      require 'activesupport'

      module Example
        module ClassMethods
          def foo; end
        end
      end

      class Consumer
        include Example
      end
    ), 'test.rb')
  end
  let(:api_map) { Solargraph::ApiMap.new.map(source) }

  it 'adds extend references' do
    allow_any_instance_of(Solargraph::External).to receive(:configured_gem_names).and_return(['activesupport'])

    pins = api_map.get_methods('Consumer', scope: :class)
    expect(pins.map(&:path)).to include('Example::ClassMethods#foo')
  end

  it 'skips without activesupport gem' do
    pins = api_map.get_methods('Consumer', scope: :class)
    expect(pins.map(&:path)).not_to include('Example::ClassMethods#foo')
  end
end
