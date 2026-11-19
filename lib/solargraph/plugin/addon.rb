# frozen_string_literal: true

module Solargraph
  module Plugin
    class Addon
      # @return [Array<String>]
      attr_reader :gem_names

      # @return [Array<Pin::Base>]
      attr_reader :pins

      # @param gem_names [Array<String>]
      # @param pins [Array<Pin::Base>]
      def initialize gem_names: [], pins: []
        @gem_names = gem_names
        @pins = pins
      end
    end
  end
end
