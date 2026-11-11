# frozen_string_literal: true

describe Solargraph::RbsMap::Helpers do
  around do |example|
    require 'tmpdir'
    Dir.mktmpdir('rspec-solargraph-') do |dir|
      @temp_dir = dir
      example.run
    end
  end

  attr_reader :temp_dir

  # @param code [String]
  # @param rbs [String]
  # @return [Solargraph::ApiMap]
  def combined_map code, rbs
    source_pins = Solargraph::SourceMap.load_string(code, 'foo.rb').pins
    File.write(File.join(temp_dir, 'foo.rbs'), rbs)
    rbs_pins = Solargraph::RbsMap::Path.pins(temp_dir)
    Solargraph::ApiMap.new(pins: described_class.combine(source_pins, rbs_pins))
  end

  describe '.combine' do
    it 'types a delegated method from its RBS signature' do
      api_map = combined_map(%(
        require 'forwardable'

        class Foo
          extend Forwardable
          def_delegator :helper, :name

          def helper
            Object.new
          end
        end
      ), %(
        class Foo
          def name: () -> String
        end
      ))

      pin = api_map.get_method_stack('Foo', 'name').first

      expect(pin.typify(api_map).to_s).to eq('String')
    end

    it 'types a method alias from its RBS signature' do
      api_map = combined_map(%(
        class Foo
          alias_method :label, :to_s
        end
      ), %(
        class Foo
          def label: () -> Symbol
        end
      ))

      pin = api_map.get_method_stack('Foo', 'label').first

      expect(pin.typify(api_map).to_s).to eq('Symbol')
    end

    it 'keeps a delegated method when its RBS signature is untyped' do
      api_map = combined_map(%(
        require 'forwardable'

        class Foo
          extend Forwardable
          def_delegator :helper, :name

          # @return [Bar]
          def helper
            Bar.new
          end
        end

        class Bar
          # @return [String]
          def name
            'bar'
          end
        end
      ), %(
        class Foo
          def name: () -> untyped
        end
      ))

      pin = api_map.get_method_stack('Foo', 'name').first

      expect(pin.typify(api_map).to_s).to eq('String')
    end
  end
end
