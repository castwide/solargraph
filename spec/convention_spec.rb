# frozen_string_literal: true

describe Solargraph::Convention do
  it 'newly defined pins are resolved by ApiMap after file changes' do
    filename = 'test.rb'

    # Initial code with one DSL call
    initial_code = <<~RUBY
      class MyModel
        dummy_dsl :existing_field
      end
    RUBY

    # Create a dummy convention that statically provides one method
    dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: [
            Solargraph::Pin::Method.new(
              name: 'existing_field',
              closure: Solargraph::Pin::Namespace.new(name: 'MyModel'),
              scope: :instance,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(1, 2, 1, 27)),
              return_type: Solargraph::ComplexType.parse('String')
            )
          ]
        )
      end
    end

    described_class.register dummy_convention

    source = Solargraph::Source.load_string(initial_code, filename)
    api_map = Solargraph::ApiMap.new
    api_map.map(source)

    # Verify that the existing method works
    pins = api_map.get_path_pins('MyModel#existing_field')
    method_pin = pins.first
    expect(method_pin).not_to be_nil
    expect(method_pin.name).to eq('existing_field')

    # Now simulate adding a new DSL call by updating the source
    updated_code = <<~RUBY
      class MyModel
        dummy_dsl :existing_field
        dummy_dsl :newly_defined_field
      end
    RUBY

    # Unregister the old convention and register a new one with two methods
    described_class.unregister dummy_convention

    updated_dummy_convention = Class.new(Solargraph::Convention::Base) do
      def local _source_map
        Solargraph::Environ.new(
          pins: [
            Solargraph::Pin::Method.new(
              name: 'existing_field',
              closure: Solargraph::Pin::Namespace.new(name: 'MyModel'),
              scope: :instance,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(1, 2, 1, 27)),
              return_type: Solargraph::ComplexType.parse('String')
            ),
            Solargraph::Pin::Method.new(
              name: 'newly_defined_field',
              closure: Solargraph::Pin::Namespace.new(name: 'MyModel'),
              scope: :instance,
              location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(2, 2, 2, 31)),
              return_type: Solargraph::ComplexType.parse('String')
            )
          ]
        )
      end
    end

    described_class.register updated_dummy_convention

    # Create an updater that represents the file being saved with new content
    updater = Solargraph::Source::Updater.new(
      filename,
      2, # version
      [
        # Replace the entire content
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(0, 0, source.code.lines.length - 1, source.code.lines.last.length),
          updated_code
        )
      ]
    )

    # Update the source
    updated_source = source.synchronize(updater)
    # Re-map the updated live source to refresh the API map - this tests the fix from 4d091c5c
    api_map.map(updated_source, live: true)

    # Now check that both methods are available
    pins = api_map.get_path_pins('MyModel#existing_field')
    method_pin = pins.first
    expect(method_pin).not_to be_nil
    expect(method_pin.name).to eq('existing_field')

    pins = api_map.get_path_pins('MyModel#newly_defined_field')
    method_pin = pins.first
    expect(method_pin).not_to be_nil
    expect(method_pin.name).to eq('newly_defined_field')

    described_class.unregister updated_dummy_convention
  end

  describe 'source transformation' do
    # Lines starting with "> " are Ruby; every other line is prose. The
    # transform keeps line count and line lengths so positions map 1:1.
    let(:fake_convention) do
      Class.new(Solargraph::Convention::Base) do
        def transform_source filename, code
          return unless filename.end_with?('.fake')
          code.gsub(/^(?:> |(.))/) { Regexp.last_match(1) ? '#' : '  ' }
        end
      end
    end

    let(:fake_code) do
      <<~FAKE
        Prose about foo
        > def foo; end
        > foo
      FAKE
    end

    before { described_class.register fake_convention }

    after { described_class.unregister fake_convention }

    it 'resolves definitions on the transformed code' do
      library = Solargraph::Library.new
      library.attach Solargraph::Source.load_string(fake_code, 'test.fake', 0)
      locations = library.definitions_at('test.fake', 2, 2).map(&:location)
      expect(locations.map(&:filename).uniq).to eq(['test.fake'])
      expect(locations.map { |loc| loc.range.start.line }.uniq).to eq([1])
    end

    it 'transforms the original text again after an edit' do
      source = Solargraph::Source.load_string("Prose\n> def foo; end\nfoo\n", 'test.fake', 0)
      change = Solargraph::Source::Change.new(Solargraph::Range.from_to(2, 0, 2, 0), '> ')
      updater = Solargraph::Source::Updater.new('test.fake', 1, [change])
      library = Solargraph::Library.new
      library.attach source.synchronize(updater)
      locations = library.definitions_at('test.fake', 2, 2).map(&:location)
      expect(locations.map { |loc| loc.range.start.line }.uniq).to eq([1])
    end

    it 'does not transform the Ruby code in directives of a transformed file' do
      source = Solargraph::Source.load_string(<<~FAKE, 'test.fake')
        > class Documented
        # @!parse def parsed; end
        # @!method generated
        > end
      FAKE
      api_map = Solargraph::ApiMap.new
      api_map.map(source)
      expect(api_map.get_path_pins('Documented#parsed')).not_to be_empty
      expect(api_map.get_path_pins('Documented#generated')).not_to be_empty
    end

    it 'leaves files that no convention claims untouched' do
      source = Solargraph::Source.load_string(fake_code, 'test.txt')
      expect(source.code).to eq(fake_code)
    end

    it 'never transforms Ruby files' do
      greedy_convention = Class.new(Solargraph::Convention::Base) do
        def transform_source _filename, _code
          'transformed = true'
        end
      end
      described_class.register greedy_convention
      source = Solargraph::Source.load_string('foo = 1', 'test.rb')
      expect(source.code).to eq('foo = 1')
    ensure
      described_class.unregister greedy_convention
    end
  end
end
