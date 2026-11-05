# frozen_string_literal: true

describe Solargraph::RbsMap::Conversions do
  context 'with RBS to digest' do
    # create a temporary directory with the scope of the spec
    around do |example|
      require 'tmpdir'
      Dir.mktmpdir('rspec-solargraph-') do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:conversions) do
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
      loader.add(path: Pathname(temp_dir))
      described_class.new(loader: loader)
    end

    let(:api_map) { Solargraph::ApiMap.new }

    before do
      rbs_file = File.join(temp_dir, 'foo.rbs')
      File.write(rbs_file, rbs)
      api_map.index conversions.pins
    end

    attr_reader :temp_dir

    context 'with overlapping module hierarchies and inheritance' do
      subject(:method_pin) { api_map.get_method_stack('A::B::C', 'foo').first }

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

      before do
        api_map.index conversions.pins
      end

      it { is_expected.to be_a(Solargraph::Pin::Method) }
    end

    context 'with self alias to self method' do
      subject(:alias_pin) { api_map.get_method_stack('Foo', 'bar?', scope: :class).first }

      let(:rbs) do
        <<~RBS
          class Foo
            def self.bar: () -> String
            alias self.bar? self.bar
          end
        RBS
      end

      it { is_expected.not_to be_nil }

      it { is_expected.to be_instance_of(Solargraph::Pin::Method) }

      it 'finds the type' do
        expect(alias_pin.return_type.tag).to eq('String')
      end
    end

    context 'with untyped response' do
      subject(:method_pin) { conversions.pins.find { |pin| pin.path == 'Foo#bar' } }

      let(:rbs) do
        <<~RBS
          class Foo
            def bar: () -> untyped
          end
        RBS
      end

      it { is_expected.not_to be_nil }

      it { is_expected.to be_a(Solargraph::Pin::Method) }

      it 'maps untyped in RBS to undefined in Solargraph' do
        expect(method_pin.return_type.tag).to eq('undefined')
      end
    end

    context 'with %a{pure} methods' do
      let(:rbs) do
        <<~RBS
          class Foo
            %a{pure}
            def bar: () -> String?

            def baz: () -> String?

            %a{pure}
            def self.qux: () -> String?

            alias quux bar
          end
        RBS
      end

      it 'marks an annotated instance method pure' do
        expect(api_map.get_method_stack('Foo', 'bar').first).to be_pure
      end

      it 'leaves an unannotated method impure' do
        expect(api_map.get_method_stack('Foo', 'baz').first).not_to be_pure
      end

      it 'marks an annotated singleton method pure' do
        expect(api_map.get_method_stack('Foo', 'qux', scope: :class).first).to be_pure
      end

      it 'carries purity to an alias of a pure method' do
        expect(api_map.get_method_stack('Foo', 'quux').first).to be_pure
      end
    end

    context 'with annotations on overloads' do
      let(:rbs) do
        <<~RBS
          class Foo
            def bar: %a{pure} () -> String | %a{pure} (Integer) -> String

            def baz: %a{pure} () -> String | (Integer) -> String
          end
        RBS
      end

      it 'keeps an annotation that every overload has' do
        expect(api_map.get_method_stack('Foo', 'bar').first).to be_pure
      end

      it 'drops an annotation that only some overloads have' do
        expect(api_map.get_method_stack('Foo', 'baz').first).not_to be_pure
      end
    end

    context 'with a reopen that only adds annotations' do
      let(:rbs) do
        <<~RBS
          class Foo
            def bar: () -> String | (Integer) -> String
          end

          class Foo
            %a{pure}
            %a{example}
            def bar: ...
          end
        RBS
      end

      it 'adds the annotations to the one method pin and keeps its signatures' do
        pins = api_map.get_path_pins('Foo#bar')
        expect(pins.length).to eq(1)
        expect(pins.first.annotations).to eq(Set['pure', 'example'])
        expect(pins.first.signatures.length).to eq(2)
      end
    end

    context 'with RBS that annotates a core method' do
      let(:rbs) do
        <<~RBS
          class Array[unchecked out E]
            %a{example}
            def sample: ...
          end
        RBS
      end

      it 'adds the annotation to the core method and keeps its signatures' do
        pins = api_map.get_path_pins('Array#sample')
        expect(pins.length).to eq(1)
        expect(pins.first.annotations).to include('example')
        expect(pins.first.signatures.length).to be > 1
      end
    end

    context 'with a module reopened under a differently spelled type parameter' do
      subject(:method_pin) { api_map.get_method_stack('StringBox', 'declared_second').first }

      let(:rbs) do
        <<~RBS
          module Boxy[unchecked out E]
            def declared_first: () -> ::Array[E]
          end

          module Boxy[unchecked out Elem]
            def declared_second: () -> ::Array[Elem]
          end

          class StringBox
            include Boxy[::String]
          end
        RBS
      end

      it 'binds the parameter by position' do
        expect(method_pin.return_type.tag).to eq('Array<String>')
      end

      it 'binds the parameter on a pin combined with Ruby source' do
        source = Solargraph::SourceMap.load_string("module Boxy\n  def declared_second; end\nend\n", 'boxy.rb')
        api_map.index Solargraph::RbsMap::Helpers.combine(source.pins, conversions.pins)

        expect(method_pin.return_type.tag).to eq('Array<String>')
      end
    end

    context 'with a class reopened under a differently spelled type parameter' do
      subject(:method_pin) { api_map.get_method_stack('Box<String>', 'declared_second').first }

      let(:rbs) do
        <<~RBS
          class Box[unchecked out E]
            def declared_first: () -> ::Array[E]
          end

          class Box[unchecked out Elem]
            def declared_second: () -> ::Array[Elem]
          end
        RBS
      end

      it 'binds the parameter by position' do
        expect(method_pin.return_type.tag).to eq('Array<String>')
      end
    end

    context 'with implicitly-returns-nil on some overloads' do
      subject(:method_pin) { conversions.pins.find { |pin| pin.path == 'Foo#bar' } }

      let(:rbs) do
        <<~RBS
          class Foo
            def bar: %a{implicitly-returns-nil} () -> String
                   | %a{implicitly-returns-nil} () { (String a) -> Integer } -> String
                   | (Integer n) -> Array[String]
                   | (Integer n) { (String a) -> Integer? } -> Array[String]
          end
        RBS
      end

      it 'adds nil to the return type of the annotated overloads' do
        expect(method_pin.signatures[0..1].map { |sig| sig.return_type.to_s }).to eq(['String, nil'] * 2)
      end

      it 'leaves the return type of the unannotated overloads alone' do
        expect(method_pin.signatures[2..3].map { |sig| sig.return_type.to_s }).to eq(['Array<String>'] * 2)
      end

      it 'does not add nil to a block return type' do
        expect(method_pin.signatures[1].block.return_type.to_s).to eq('Integer')
      end

      it 'keeps nil in a block return type declared optional in RBS' do
        expect(method_pin.signatures[3].block.return_type.to_s).to eq('Integer, nil')
      end
    end

    # https://github.com/castwide/solargraph/issues/1255
    context 'with a type alias used as a parameter type' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type path = String | Integer

          class Foo
            def bar: (path src) -> void
          end
        RBS
      end

      it 'expands the alias to its underlying union instead of a nominal tag' do
        expect(parameter.return_type.rooted_tags).to eq('::String, ::Integer')
      end
    end

    # https://github.com/castwide/solargraph/issues/1255
    context 'with a type alias declared after the class that references it' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          class Foo
            def bar: (path src) -> void
          end

          type path = String | Integer
        RBS
      end

      it 'still expands the alias to its underlying union' do
        expect(parameter.return_type.rooted_tags).to eq('::String, ::Integer')
      end
    end

    # https://github.com/castwide/solargraph/pull/1281#issuecomment-5270350329
    context 'with a type alias that references a name declared only in RBS core' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type wrapped_path = ::path

          class Foo
            def bar: (wrapped_path src) -> void
          end
        RBS
      end

      it 'expands the alias instead of falling back to a self-referential nominal tag' do
        expect(parameter.return_type.rooted_tags).to eq('::String, ::_ToStr, ::_ToPath')
      end
    end

    context 'with a core alias reference loaded through a stdlib-less RbsMap' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:conversions) { Solargraph::RbsMap::Path.new(temp_dir) }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type wrapped_path = ::path

          class Foo
            def bar: (wrapped_path src) -> void
          end
        RBS
      end

      it 'expands the alias' do
        expect(parameter.return_type.rooted_tags).to eq('::String, ::_ToStr, ::_ToPath')
      end
    end

    context 'with a core alias reference alongside a shim that redeclares a core name' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type wrapped_path = ::path

          interface ::_ToPath
            def to_path: () -> String
          end

          class Foo
            def bar: (wrapped_path src) -> void
          end
        RBS
      end

      it 'falls back to the nominal alias tag' do
        expect(parameter.return_type.rooted_tags).to eq('path')
      end
    end

    # https://github.com/castwide/solargraph/issues/1255
    context 'with a recursive type alias' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type json = String | Array[json]

          class Foo
            def bar: (json src) -> void
          end
        RBS
      end

      it 'does not crash expanding it' do
        expect { conversions.pins }.not_to raise_error
      end

      it 'falls back to the nominal alias tag once a cycle is detected' do
        expect(parameter.return_type.rooted_tags).to eq('::String, ::Array<json>')
      end
    end

    # https://github.com/castwide/solargraph/issues/1255
    context 'with a generic type alias' do
      subject(:parameter) { method_pin.signatures.first.parameters.first }

      let(:method_pin) { api_map.get_method_stack('Foo', 'bar', scope: :instance).first }

      let(:rbs) do
        <<~RBS
          type box[T] = Array[T] | nil

          class Foo
            def bar: (box[String] src) -> void
          end
        RBS
      end

      it 'falls back to the nominal alias tag instead of leaking an unbound generic' do
        expect(parameter.return_type.rooted_tags).not_to include('generic<')
      end
    end

    context 'with a prepended module' do
      subject(:prepend_pin) do
        conversions.pins.find { |pin| pin.is_a?(Solargraph::Pin::Reference::Prepend) && pin.namespace == 'Foo' }
      end

      let(:rbs) do
        <<~RBS
          module Bar
            def baz: () -> String
          end

          class Foo
            prepend Bar
          end
        RBS
      end

      it 'generates a prepend reference naming the module' do
        expect(prepend_pin.name).to eq('Bar')
      end
    end
  end

  context 'with standard loads for solargraph project' do
    before :all do # rubocop:disable RSpec/BeforeAfterAll
      @api_map = Solargraph::ApiMap.load_with_cache('.')
    end

    let(:api_map) { @api_map }

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
        # RBS core's Hash#[] started taking its key as the _Key duck-type
        # interface instead of the generic K as of RBS 4.1.0, so instantiating
        # Hash{Symbol => untyped} no longer substitutes the param type on
        # newer RBS - see ruby/rbs core/hash.rbs.
        expected = if Gem::Version.new(RBS::VERSION) >= Gem::Version.new('4.1.0')
                     ['::Hash::_Key']
                   else
                     ['Symbol']
                   end
        expect(sup_method_stack.flat_map(&:signatures).flat_map(&:parameters).map(&:return_type).map(&:rooted_tags)
                 .uniq).to eq(expected)
      end
    end
  end

  if Gem::Version.new(RBS::VERSION) >= Gem::Version.new('3.9.1')
    context 'with method pin for Open3.capture2e' do
      it 'accepts chdir kwarg' do
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
