# frozen_string_literal: true

describe Solargraph::Plugin::ActiveSupport do
  let(:source) do
    Solargraph::Source.load_string(%(
      require 'activesupport'

      module Example
        class_attribute :class_attribute1
        class_attribute :class_attribute2, :class_attribute3

        module ClassMethods
          def foo; end
        end
      end

      class Consumer
        include Example
      end
    ), 'test.rb')
  end
  let(:attribute_methods) do
    %w[
      Example.class_attribute1 Example.class_attribute2 Example.class_attribute3
      Example.class_attribute1= Example.class_attribute2= Example.class_attribute3=
      Example.class_attribute1? Example.class_attribute2? Example.class_attribute3?
    ]
  end
  let(:api_map) { Solargraph::ApiMap.new.map(source) }

  context 'with the activesupport gem' do
    before(:each) do
      allow_any_instance_of(Solargraph::External).to receive(:configured_gem_names).and_return(['activesupport'])
    end

    it 'adds extend references' do
      pins = api_map.get_methods('Consumer', scope: :class)
      expect(pins.map(&:path)).to include('Example::ClassMethods#foo')
    end

    it 'adds attribute methods' do
      invalid = attribute_methods.reject { |path| api_map.get_path_pins(path).one? }
      expect(invalid).to be_empty
    end
  end

  it 'skips without activesupport gem' do
    pins = api_map.get_methods('Consumer', scope: :class)
    expect(pins.map(&:path)).not_to include('Example::ClassMethods#foo')
  end
end
