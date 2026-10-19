# frozen_string_literal: true

require 'forwardable'

module Solargraph
  module Plugin
    class Base
      extend Forwardable

      attr_reader :panel

      def_delegators :@panel, :pins, :pins_by_class, :pins_by_path, :gem_names

      # @param panel [Panel]
      def initialize panel
        @panel = panel
      end

      # @return [Addon]
      def addon
        EMPTY_ADDON
      end
    end
  end
end
