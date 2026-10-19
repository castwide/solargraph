# frozen_string_literal: true

module Solargraph
  module Plugin
    class Addon
      attr_reader :gem_names, :pins

      # @param gem_names [Array<String>]
      # @param pins [Array<Pin::Base>]
      def initialize gem_names: [], pins: []
        @gem_names = gem_names
        @pins = pins
      end
    end

    EMPTY_ADDON = Addon.new.freeze
  end
end
