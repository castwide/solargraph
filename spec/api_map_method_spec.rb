# frozen_string_literal: true

describe Solargraph::ApiMap do
  let(:api_map) { described_class.new }
  let(:bench) do
    Solargraph::Bench.new(external_requires: external_requires, workspace: Solargraph::Workspace.new('.'))
  end
  let(:external_requires) { [] }

  before do
    api_map.catalog bench
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

      api_map = described_class.new.map(source)

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

      api_map = described_class.new.map(source)

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

      api_map = described_class.new.map(source)

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

      api_map = described_class.new.map(source)

      clip = api_map.clip_at('test.rb', [15, 8])
      expect(clip.infer.to_s).to eq('Symbol')
    end
  end

  describe '#get_method_stack' do
    let(:out) { StringIO.new }
    let(:api_map) { described_class.load_with_cache(Dir.pwd, out) }

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
end
