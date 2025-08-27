describe Solargraph::RbsMap::Conversions do
  context 'with custom RBS files' do
    # create a temporary directory with the scope of the spec
    around do |example|
      require 'tmpdir'
      Dir.mktmpdir("rspec-solargraph-") do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:rbs_repo) do
      RBS::Repository.new(no_stdlib: false)
    end

    let(:loader) do
      RBS::EnvironmentLoader.new(core_root: nil, repository: rbs_repo)
    end

    let(:conversions) do
      Solargraph::RbsMap::Conversions.new(loader: loader)
    end

    let(:pins) do
      conversions.pins
    end

    before do
      rbs_file = File.join(temp_dir, 'foo.rbs')
      File.write(rbs_file, rbs)
      loader.add(path: Pathname(temp_dir))
    end

    attr_reader :temp_dir

    context 'with untyped response' do
      let(:rbs) do
        <<~RBS
          class Foo
            def bar: () -> untyped
          end
        RBS
      end

      subject(:method_pin) { pins.find { |pin| pin.path == 'Foo#bar' } }

      it { should_not be_nil }

      it { should be_a(Solargraph::Pin::Method) }

      it 'maps untyped in RBS to undefined in Solargraph 'do
        expect(method_pin.return_type.tag).to eq('undefined')
      end
    end
  end

  context 'with standard loads for solargraph project' do
    before :all do # rubocop:disable RSpec/BeforeAfterAll
      @api_map = Solargraph::ApiMap.load_with_cache('.')
    end

    let(:api_map) { @api_map } # rubocop:disable RSpec/InstanceVariable

    context 'with superclass pin for Parser::AST::Node' do
      let(:superclass_pin) do
        api_map.pins.find do |pin|
          pin.is_a?(Solargraph::Pin::Reference::Superclass) && pin.context.namespace == 'Parser::AST::Node'
        end
      end

      it 'generates a rooted pin' do
        # rooted!
        expect(superclass_pin&.name).to eq('::AST::Node')
      end
    end
  end
end
