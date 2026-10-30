# frozen_string_literal: true

module Solargraph
  module Plugin
    autoload :Addon, 'solargraph/plugin/addon'
    autoload :Base, 'solargraph/plugin/base'
    autoload :Panel, 'solargraph/plugin/panel'
    autoload :ActiveSupport, 'solargraph/plugin/active_support'

    EMPTY_ADDON = Addon.new.freeze

    # @return [Set<Class<Plugin::Base>>]
    def self.registry
      @registry ||= Set.new
    end

    # @param klass [Class<Plugin::Base>]
    # @return [Set<Class<Plugin::Base>>]
    def self.register klass
      registry.add klass
    end

    # @param klass [Class<Plugin::Base>]
    # @return [Set<Class<Plugin::Base>>]
    def self.unregister klass
      registry.delete klass
    end

    Plugin.register ActiveSupport
  end
end
