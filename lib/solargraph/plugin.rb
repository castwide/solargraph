# frozen_string_literal: true

module Solargraph
  module Plugin
    autoload :Addon, 'solargraph/plugin/addon'
    autoload :Base, 'solargraph/plugin/base'
    autoload :Panel, 'solargraph/plugin/panel'
    autoload :ActiveSupport, 'solargraph/plugin/active_support'

    def self.registry
      @registry ||= Set.new
    end

    def self.register klass
      registry.add klass
    end

    def self.unregister klass
      registry.delete klass
    end
  end
end
