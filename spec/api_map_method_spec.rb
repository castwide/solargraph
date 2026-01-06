# frozen_string_literal: true

describe 'Solargraph::ApiMap methods' do
  let(:api_map) { Solargraph::ApiMap.new }
  let(:bench) do
    Solargraph::Bench.new(external_requires: external_requires, workspace: Solargraph::Workspace.new('.'))
  end
  let(:external_requires) { [] }

  before do
    api_map.catalog bench
  end

  describe '#resolve_method_alias' do
    it 'resolves the IO.for_fd alias to IO.new' do
      stack = api_map.get_method_stack('IO', 'for_fd', scope: :class)
      expect(stack.map(&:class).uniq).to eq([Solargraph::Pin::Method])
    end
  end

  describe '#qualify' do
    let(:external_requires) { ['yaml'] }

    it 'understands alias namespaces resolving types' do
      source = Solargraph::Source.load_string(%(
        class Foo
          # @return [Symbol]
          def bing; end
        end

        module Bar
          Baz = ::Foo
        end

        a = Bar::Baz.new.bing
        a
        Bar::Baz
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)

      clip = api_map.clip_at('test.rb', [11, 8])
      expect(clip.infer.to_s).to eq('Symbol')
    end

    it 'understands nested alias namespaces to nested classes resolving types' do
      source = Solargraph::Source.load_string(%(
        module A
          class Foo
            # @return [Symbol]
            def bing; end
          end
        end

        module Bar
          Baz = A::Foo
        end

        a = Bar::Baz.new.bing
        a
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)

      clip = api_map.clip_at('test.rb', [13, 8])
      expect(clip.infer.to_s).to eq('Symbol')
    end

    it 'understands nested alias namespaces resolving types' do
      source = Solargraph::Source.load_string(%(
        module Bar
          module A
            class Foo
              # @return [Symbol]
              def bing; :bingo; end
            end
          end
        end

        module Bar
          Foo = A::Foo
        end

        a = Bar::Foo.new.bing
        a
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)

      clip = api_map.clip_at('test.rb', [15, 8])
      expect(clip.infer.to_s).to eq('Symbol')
    end

    it 'understands includes using nested alias namespaces resolving types' do
      source = Solargraph::Source.load_string(%(
        module Foo
          # @return [Symbol]
          def bing; :yay; end
        end

        module Bar
          Baz = Foo
        end

        class B
          include Foo
        end

        a = B.new.bing
        a
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new.map(source)

      clip = api_map.clip_at('test.rb', [15, 8])
      expect(clip.infer.to_s).to eq('Symbol')
    end
  end

  describe '#get_method_stack' do
    let(:out) { StringIO.new }
    let(:api_map) { Solargraph::ApiMap.load_with_cache(Dir.pwd, out) }

    context 'with stdlib that has vital dependencies' do
      let(:external_requires) { ['yaml'] }
      let(:method_stack) { api_map.get_method_stack('YAML', 'safe_load', scope: :class) }

      it 'handles the YAML gem aliased to Psych' do
        expect(method_stack).not_to be_empty
      end
    end

    context 'with thor' do
      let(:external_requires) { ['thor'] }
      let(:method_stack) { api_map.get_method_stack('Thor', 'desc', scope: :class) }

      it 'handles finding Thor.desc' do
        expect(method_stack).not_to be_empty
      end
    end
  end

  describe '#cache_all!' do
    it 'can cache gems without a bench' do
      api_map = Solargraph::ApiMap.new
      doc_map = instance_double(Solargraph::DocMap, cache_all!: true)
      allow(Solargraph::DocMap).to receive(:new).and_return(doc_map)
      api_map.cache_all!($stderr)
      expect(doc_map).to have_received(:cache_all!).with($stderr)
    end
  end

  describe '#cache_gem' do
    it 'can cache gem without a bench' do
      api_map = Solargraph::ApiMap.new
      expect { api_map.cache_gem('rake', out: StringIO.new) }.not_to raise_error
    end
  end

  describe '#workspace' do
    it 'can get a default workspace without a bench' do
      api_map = Solargraph::ApiMap.new
      expect(api_map.workspace).not_to be_nil
    end
  end

  describe '#uncached_gemspecs' do
    it 'can get uncached gemspecs workspace without a bench' do
      api_map = Solargraph::ApiMap.new
      expect(api_map.uncached_gemspecs).not_to be_nil
    end
  end

  describe '#get_methods' do
    it 'recognizes mixin references from context' do
      source = Solargraph::Source.load_string(%(
        module Foo
          module Bar
            def baz; end
          end

          class Includer
            include Bar
          end
        end
      ), 'test.rb')

      api_map = Solargraph::ApiMap.new
      api_map.map source
      pins = api_map.get_methods('Foo::Includer')
      expect(pins.map(&:path)).to include('Foo::Bar#baz')
    end
  end
end
