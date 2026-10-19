# frozen_string_literal: true

module Solargraph
  module Plugin
    class ActiveSupport < Base
      def addon
        return EMPTY_ADDON unless gem_names.include?('activesupport')

        pins = pins_by_class(Pin::Reference::Include).map do |inc|
          Pin::Reference::Extend.new(name: "#{inc.name}::ClassMethods", closure: inc.closure)
        end

        Addon.new(pins: pins)
      end
    end

    Plugin.register ActiveSupport
  end
end
