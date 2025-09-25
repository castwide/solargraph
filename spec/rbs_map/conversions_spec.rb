describe Solargraph::RbsMap::Conversions do
  context 'with RBS to digest' do
    # create a temporary directory with the scope of the spec
    around do |example|
      require 'tmpdir'
      Dir.mktmpdir("rspec-solargraph-") do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:conversions) do
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
      loader.add(path: Pathname(temp_dir))
      Solargraph::RbsMap::Conversions.new(loader: loader)
    end

    let(:api_map) { Solargraph::ApiMap.new }

    before do
      rbs_file = File.join(temp_dir, 'foo.rbs')
      File.write(rbs_file, rbs)
      api_map.index conversions.pins
    end

    attr_reader :temp_dir

    context 'with self alias to self method' do
      let(:rbs) do
        <<~RBS
          class Foo
            def self.bar: () -> String
            alias self.bar? self.bar
          end
        RBS
      end

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :class).first }

      subject(:alias_pin) { api_map.get_method_stack('Foo', 'bar?', scope: :class).first }

      it { should_not be_nil }

      it { should be_instance_of(Solargraph::Pin::Method) }

      it 'finds the type' do
        expect(alias_pin.return_type.tag).to eq('String')
      end
    end

    context 'with untyped response' do
      let(:rbs) do
        <<~RBS
          class Foo
            def bar: () -> untyped
          end
        RBS
      end

      subject(:method_pin) { conversions.pins.find { |pin| pin.path == 'Foo#bar' } }

      it { should_not be_nil }

      it { should be_a(Solargraph::Pin::Method) }

      it 'maps untyped in RBS to undefined in Solargraph 'do
        expect(method_pin.return_type.tag).to eq('undefined')
      end
    end

    # https://github.com/castwide/solargraph/issues/1042
    context 'with Hash superclass with untyped value and alias' do
      let(:rbs) do
        <<~RBS
          class Sub < Hash[Symbol, untyped]
            alias meth_alias []
          end
        RBS
      end

      let(:sup_method_stack) { api_map.get_method_stack('Hash{Symbol => undefined}', '[]', scope: :instance) }

      let(:sub_alias_stack) { api_map.get_method_stack('Sub', 'meth_alias', scope: :instance) }

      it 'does not crash looking at superclass method' do
        expect { sup_method_stack }.not_to raise_error
      end

      it 'does not crash looking at alias' do
        expect { sub_alias_stack }.not_to raise_error
      end

      it 'finds superclass method pin return type' do
        expect(sup_method_stack.map(&:return_type).map(&:rooted_tags).uniq).to eq(['undefined'])
      end

      it 'finds superclass method pin parameter type' do
        expect(sup_method_stack.flat_map(&:signatures).flat_map(&:parameters).map(&:return_type).map(&:rooted_tags)
                 .uniq).to eq(['Symbol'])
      end
    end

    context 'with overlapping module hierarchies and inheritance' do
      let(:rbs) do
        <<~RBS
          module B
            class C
              def foo: () -> String
            end
          end
          module A
            module B
              class C < ::B::C
              end
            end
          end
        RBS
      end

      subject(:method_pin) { api_map.get_method_stack('A::B::C', 'foo').first }

      it { should be_a(Solargraph::Pin::Method) }
    end
  end

  if Gem::Version.new(RBS::VERSION) >= Gem::Version.new('3.9.1')
    context 'with method pin for Open3.capture2e' do
      it 'accepts chdir kwarg' do
        pending('https://github.com/castwide/solargraph/pull/1005')
        api_map = Solargraph::ApiMap.load_with_cache('.', $stdout)

        method_pin = api_map.pins.find do |pin|
          pin.is_a?(Solargraph::Pin::Method) && pin.path == 'Open3.capture2e'
        end

        chdir_param = method_pin&.signatures&.flat_map(&:parameters)&.find do |param| # rubocop:disable Style/SafeNavigationChainLength
          param.name == 'chdir'
        end
        expect(chdir_param).not_to be_nil, -> { "Found pin #{method_pin.to_rbs} from #{method_pin.type_location}" }
      end
    end
  end
end
