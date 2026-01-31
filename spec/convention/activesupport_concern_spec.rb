# frozen_string_literal: true

describe Solargraph::Convention::ActiveSupportConcern do
  let(:api_map) { Solargraph::ApiMap.new.map(source) }

  context 'with a simple activesupport concern' do
    let :source do
      Solargraph::Source.load_string(%(
      # Example from here: https://api.rubyonrails.org/v7.0/classes/ActiveSupport/Concern.html
      require "active_support/concern"

      module Foo
        extend ActiveSupport::Concern
        included do
          def self.method_injected_by_foo
              puts 'test'
          end
        end
      end

      module Bar
        extend ActiveSupport::Concern
        include Foo

        included do
          self.method_injected_by_foo
        end
      end

      class Host
        include Bar # It works, now Bar takes care of its dependencies
      end

      # this should print 'test'
    ), 'test.rb')
    end

    it 'handles block method super scenarios' do
      api_map = Solargraph::ApiMap.new.map(source)

      pin = api_map.get_method_stack('Host', 'method_injected_by_foo', scope: :class)
      expect(pin.map(&:name)).to eq(['method_injected_by_foo'])
    end
  end

  context 'with static method defined in both included module and class' do
    let :source do
      Solargraph::Source.load_string(%(
      # Example from here: https://api.rubyonrails.org/v7.0/classes/ActiveSupport/Concern.html
      require "active_support/concern"

      module Foo
        extend ActiveSupport::Concern
        included do
          def self.my_method
              puts 'test'
          end
        end
      end

      module Bar
        extend ActiveSupport::Concern
        include Foo

        included do
          self.my_method
        end
      end

      class B
        # @return [Numeric]
        def self.my_method; end
      end

      class A < B
        include Bar # It works, now Bar takes care of its dependencies

        def self.my_method; end
      end

      # this should print 'test'
    ), 'test.rb')
    end

    let(:pins) { api_map.get_method_stack('A', 'my_method', scope: :class) }

    it 'sees all three methods' do
      expect(pins.map(&:name)).to eq(%w[my_method my_method my_method])
    end

    it 'prefers directly defined method' do
      expect(pins.map(&:path).first).to eq('A.my_method')
    end

    it 'is able to typify from superclass' do
      expect(pins.first.typify(api_map).map(&:tag)).to include('Numeric')
    end
  end

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

    context 'with Inheritance module in ActiveRecord' do
      # See
      # https://github.com/ruby/gem_rbs_collection/blob/main/gems/activerecord/6.0/activerecord-generated.rbs
      # for full RBS
      subject(:method_pins) { api_map.get_method_stack('MyActiveRecord::Base', 'abstract_class', scope: :class) }

      let(:rbs) do
        <<~RBS
          module MyActiveRecord
            module Inheritance
              extend ActiveSupport::Concern

              module ClassMethods
                attr_accessor abstract_class: untyped
              end
            end
          end

          module MyActiveRecord
            class Base
              include Inheritance
            end
          end
        RBS
      end

      it { is_expected.not_to be_empty }

      it "has one item" do
        expect(method_pins.size).to eq(1)
      end

      it "is a Pin::Method" do
        expect(method_pins.first).to be_a(Solargraph::Pin::Method)
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
  end
end
