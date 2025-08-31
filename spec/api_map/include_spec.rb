# frozen_string_literal: true

describe Solargraph::ApiMap do
  let(:api_map) { described_class.new.map(source) }

  context 'with a non-rooted include in local source' do
    let :source do
      Solargraph::Source.load_string(%(
      module A
        module B
          # @return [String]
          def foo
            'foo'
          end
        end
      end

      class A::C
        include B
      end
    ), 'test.rb')
    end

    it 'understands method' do
      pin = api_map.get_method_stack('A::B', 'foo', scope: :instance)
      expect(pin.map(&:return_type).map(&:tags)).to eq(['String'])
    end

    it 'handles includes via relative name' do
      api_map = described_class.new.map(source)

      pin = api_map.get_method_stack('A::C', 'foo', scope: :instance)
      expect(pin.map(&:return_type).map(&:rooted_tags)).to eq(['String'])
    end
  end

  context 'with a non-rooted include in RBS' do
    # create a temporary directory with the scope of the spec
    around do |example|
      require 'tmpdir'
      Dir.mktmpdir('rspec-solargraph-') do |dir|
        @temp_dir = dir
        example.run
      end
    end

    attr_reader :temp_dir

    let(:rbs) do
      <<~RBS
        module A
          module B
            def foo: () -> String
          end

          class E
            def foo: () -> String
          end

          class D < C
          end
        end
        class A::C
          include B
        end
      RBS
    end

    let(:conversions) do
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
      loader.add(path: Pathname(temp_dir))
      Solargraph::RbsMap::Conversions.new(loader: loader)
    end

    let(:api_map) { described_class.new pins: conversions.pins }

    before do
      rbs_file = File.join(temp_dir, 'foo.rbs')
      File.write(rbs_file, rbs)
    end

    it 'understands method' do
      pin = api_map.get_method_stack('A::B', 'foo', scope: :instance)
      expect(pin.map(&:return_type).map(&:tags)).to eq(['String'])
    end

    it 'handles includes via relative name' do
      pin = api_map.get_method_stack('A::C', 'foo', scope: :instance)
      expect(pin.map(&:return_type).map(&:tags)).to eq(['String'])
    end
  end
end
