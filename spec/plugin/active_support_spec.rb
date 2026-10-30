# frozen_string_literal: true

describe Solargraph::Plugin::ActiveSupport do
  # @param namespace [String]
  # @param code [String]
  # @return [Array<Solargraph::Pin::Method>]
  def method_pins_for namespace, code
    Solargraph::SourceMap.load_string(code).pins.select do |pin|
      pin.is_a?(Solargraph::Pin::Method) && pin.namespace == namespace
    end
  end

  # @return [Array<Array(String, Symbol)>]
  def accessors pins
    pins.map { |pin| [pin.name, pin.context.scope] }.sort
  end

  describe 'ClassMethods' do
    let(:source) do
      Solargraph::Source.load_string(%(
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

    context 'with the activesupport gem' do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Solargraph::External).to receive(:configured_gem_names).and_return(['activesupport'])
      end

      it 'adds extend references' do
        pins = api_map.get_methods('Consumer', scope: :class)
        expect(pins.map(&:path)).to include('Example::ClassMethods#foo')
      end

      context 'when the include is in a gem' do
        let(:gem_pins) do
          Solargraph::SourceMap.load_string(%(
            module GemExample
              module ClassMethods
                def bar; end
              end
            end

            class GemConsumer
              include GemExample
            end
          ), 'gem.rb').pins
        end

        before do
          # rubocop:disable-next RSpec/AnyInstance
          allow_any_instance_of(Solargraph::External).to receive(:pins) { gem_pins.clone }
        end

        it 'adds extend references' do
          pins = api_map.get_methods('GemConsumer', scope: :class)
          expect(pins.map(&:path)).to include('GemExample::ClassMethods#bar')
        end
      end
    end

    context 'without the activesupport gem' do
      it 'skips without activesupport gem' do
        pins = api_map.get_methods('Consumer', scope: :class)
        expect(pins.map(&:path)).not_to include('Example::ClassMethods#foo')
      end
    end
  end

  describe 'attribute methods' do
    # @param namespace [String]
    # @param code [String]
    # @return [Array<Solargraph::Pin::Method>]
    def method_pins_for namespace, code
      source = Solargraph::Source.load_string(code)
      Solargraph::ApiMap.new
                        .map(source)
                        .pins
                        .select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.path&.start_with?(namespace) }
    end

    # @return [Array<Array(String, Symbol)>]
    def accessors pins
      pins.map { |pin| [pin.name, pin.context.scope] }.sort
    end

    context 'with the activesupport gem' do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Solargraph::External).to receive(:configured_gem_names).and_return(['activesupport'])
      end

      it 'generates accessors for class_attribute' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance],
                                        ['bar?', :class],
                                        ['bar?', :instance]
                                      ])
      end

      it 'generates accessors for multiple attributes' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar, :baz
          end
        )
        expect(pins.count { |pin| pin.name.start_with?('bar') }).to eq(6)
        expect(pins.count { |pin| pin.name.start_with?('baz') }).to eq(6)
      end

      it 'omits instance accessors when instance_accessor is false' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar, instance_accessor: false
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar=', :class],
                                        ['bar?', :class]
                                      ])
      end

      it 'omits instance writers when instance_writer is false' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar, instance_writer: false
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar?', :class],
                                        ['bar?', :instance]
                                      ])
      end

      it 'omits predicates when instance_predicate is false' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar, instance_predicate: false
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance]
                                      ])
      end

      it 'keeps instance accessors when instance_accessor is not a literal boolean' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar, instance_accessor: Rails.env.test?
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance],
                                        ['bar?', :class],
                                        ['bar?', :instance]
                                      ])
      end

      it 'marks generated accessors as attributes' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar
          end
        )
        expect(pins.all?(&:attribute?)).to be(true)
      end

      it 'gives class attribute writers a single parameter' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class_attribute :bar
          end
        )
        writers = pins.select { |pin| pin.name == 'bar=' }
        expect(writers.size).to eq(2)
        expect(writers.all? { |pin| pin.parameters.map(&:name) == ['value'] }).to be(true)
      end

      it 'generates module and instance accessors for mattr_accessor' do
        pins = method_pins_for 'Foo', %(
          module Foo
            mattr_accessor :bar
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance]
                                      ])
      end

      it 'treats cattr_accessor as mattr_accessor' do
        pins = method_pins_for 'Foo', %(
          class Foo
            cattr_accessor :bar, :baz
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance],
                                        ['baz', :class],
                                        ['baz', :instance],
                                        ['baz=', :class],
                                        ['baz=', :instance]
                                      ])
      end

      it 'generates only readers for mattr_reader and cattr_reader' do
        %w[mattr_reader cattr_reader].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar
            end
          )
          expect(accessors(pins)).to eq([['bar', :class], ['bar', :instance]])
        end
      end

      it 'generates only writers for mattr_writer and cattr_writer' do
        %w[mattr_writer cattr_writer].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar
            end
          )
          expect(accessors(pins)).to eq([['bar=', :class], ['bar=', :instance]])
        end
      end

      it 'omits module attribute instance accessors when instance_accessor is false' do
        %w[mattr_accessor config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar, instance_accessor: false
            end
          )
          expect(accessors(pins)).to eq([['bar', :class], ['bar=', :class]])
        end
      end

      it 'omits module attribute instance readers when instance_reader is false' do
        %w[mattr_accessor config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar, instance_reader: false
            end
          )
          expect(accessors(pins)).to eq([['bar', :class], ['bar=', :class], ['bar=', :instance]])
        end
      end

      it 'omits module attribute instance writers when instance_writer is false' do
        %w[mattr_accessor config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar, instance_writer: false
            end
          )
          expect(accessors(pins)).to eq([['bar', :class], ['bar', :instance], ['bar=', :class]])
        end
      end

      it 'omits the instance reader of mattr_reader when instance_accessor is false' do
        pins = method_pins_for 'Foo', %(
          class Foo
            mattr_reader :bar, instance_accessor: false, default: 1
          end
        )
        expect(accessors(pins)).to eq([['bar', :class]])
      end

      it 'generates class and instance accessors for config_accessor' do
        pins = method_pins_for 'Foo', %(
          class Foo
            include ActiveSupport::Configurable
            config_accessor :bar
          end
        )
        expect(accessors(pins)).to eq([
                                        ['bar', :class],
                                        ['bar', :instance],
                                        ['bar=', :class],
                                        ['bar=', :instance]
                                      ])
      end

      it 'maps module attributes declared with a default block' do
        %w[mattr_accessor config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro}(:bar) { [] }
            end
          )
          expect(accessors(pins).map(&:first)).to eq(%w[bar bar bar= bar=])
        end
      end

      it 'makes module attribute accessors public after private' do
        pins = method_pins_for 'Foo', %(
          class Foo
            private
            mattr_accessor :bar
            config_accessor :baz
          end
        )
        expect(pins.map(&:visibility).uniq).to eq([:public])
      end

      it 'does not map module attributes declared on a singleton class' do
        pins = method_pins_for 'Foo', %(
          class Foo
            class << self
              mattr_accessor :bar
              config_accessor :baz
            end
          end
        )
        expect(pins).to be_empty
      end

      it 'skips module attribute names Rails rejects' do
        pins = method_pins_for 'Foo', %(
          class Foo
            mattr_accessor :"bad-name", :ok
          end
        )
        expect(pins.map(&:name).uniq).to eq(%w[ok ok=])
      end

      it 'maps module attributes declared in a concern included block onto the concern' do
        pins = method_pins_for 'Foo', %(
          module Foo
            extend ActiveSupport::Concern
            included do
              cattr_accessor :logger
            end
          end
        )
        expect(accessors(pins)).to eq([
                                        ['logger', :class],
                                        ['logger', :instance],
                                        ['logger=', :class],
                                        ['logger=', :instance]
                                      ])
      end

      it 'gives module attribute writers a single parameter' do
        pins = method_pins_for 'Foo', %(
          class Foo
            mattr_writer :bar
          end
        )
        expect(pins.all? { |pin| pin.parameters.map(&:name) == ['value'] }).to be(true)
      end

      it 'types accessors from a literal default' do
        pending 'Maybe not'
        %w[class_attribute mattr_accessor cattr_accessor mattr_reader mattr_writer config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar, default: false
            end
          )
          accessor_pins = pins.reject { |pin| pin.name.end_with?('?') }
          expect(accessor_pins.map { |pin| pin.return_type.to_s }.uniq).to eq(['Boolean']), macro
        end
      end

      it 'infers the type of each kind of literal default' do
        pending 'Maybe not'
        {
          '1' => 'Integer', '1.5' => 'Float', "'baz'" => 'String', ':baz' => 'Symbol',
          '[]' => 'Array', '{}' => 'Hash'
        }.each do |literal, type|
          pins = method_pins_for 'Foo', %(
            class Foo
              mattr_accessor :bar, default: #{literal}
            end
          )
          expect(pins.map { |pin| pin.return_type.to_s }.uniq).to eq([type]), literal
        end
      end

      it 'leaves accessors with a nil default untyped' do
        pins = method_pins_for 'Foo', %(
          class Foo
            mattr_accessor :bar, default: nil
          end
        )
        expect(pins.map(&:return_type).all?(&:undefined?)).to be(true)
        expect(pins.flat_map(&:parameters).map(&:return_type).all?(&:undefined?)).to be(true)
      end

      it 'types the writer parameter from a literal default' do
        pending 'Maybe not'
        %w[class_attribute mattr_accessor mattr_writer config_accessor].each do |macro|
          pins = method_pins_for 'Foo', %(
            class Foo
              #{macro} :bar, default: 1
            end
          )
          writers = pins.select { |pin| pin.name.end_with?('=') }
          expect(writers.flat_map(&:parameters).map { |param| param.return_type.to_s }.uniq).to eq(['Integer']), macro
        end
      end

      it 'leaves accessors with a non-literal default untyped' do
        pins = method_pins_for 'Foo', %(
          class Foo
            mattr_accessor :bar, default: Baz.new
          end
        )
        expect(pins.map(&:return_type).all?(&:undefined?)).to be(true)
      end

      it 'prefers an explicit @return tag to the default literal type' do
        pins = method_pins_for 'Foo', %(
          class Foo
            # @return [String, nil]
            mattr_accessor :bar, default: 1
          end
        )
        expect(pins.map { |pin| pin.return_type.to_s }.uniq).to eq(['String, nil'])
        writer_params = pins.select { |pin| pin.name.end_with?('=') }.flat_map(&:parameters)
        expect(writer_params.map { |param| param.return_type.to_s }).not_to include('Integer')
      end

      it 'resolves a literal default type through the ApiMap' do
        pending 'Maybe not'
        source = Solargraph::Source.load_string(%(
          class Foo
            cattr_accessor :bar, instance_accessor: false, default: false
          end
        ), 'test.rb')
        api_map = Solargraph::ApiMap.new
        api_map.map source
        %w[bar bar=].each do |name|
          pin = api_map.get_method_stack('Foo', name, scope: :class).first
          expect(pin.typify(api_map).to_s).to eq('Boolean'), name
        end
      end
    end
  end
end
