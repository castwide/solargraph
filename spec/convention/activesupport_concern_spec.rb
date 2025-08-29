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
end
