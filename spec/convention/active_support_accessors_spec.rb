# frozen_string_literal: true

describe Solargraph::Convention::ActiveSupportAccessors do
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
end
