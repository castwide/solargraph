# frozen_string_literal: true

describe Solargraph::Convention::ActiveSupportConcern do
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
