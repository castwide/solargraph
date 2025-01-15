# frozen_string_literal: true

require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    # Ruby stdlib pins
    #
    class StdlibMap < RbsMap
      # @type [Hash{String => RbsMap}]
      @stdlib_maps_hash = {}

      # @param library [String]
      def initialize library
        cache = Cache.load('stdlib', "#{library}.ser")
        if cache
          pins.replace cache
        else
          super
          if library == 'yaml'
            pins.push Solargraph::Pin::Constant.new(name: 'YAML', comments: '@return [Module<Psych>]', closure: Pin::ROOT_PIN)
          end
          Cache.save('stdlib', "#{library}.ser", pins)
        end
      end

      # @param library [String]
      # @return [StdlibMap]
      def self.load library
        @stdlib_maps_hash[library] ||= StdlibMap.new(library)
      end

      def repository
        @repository ||= RBS::Repository.new
      end
    end
  end
end
