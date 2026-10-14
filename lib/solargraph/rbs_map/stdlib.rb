# frozen_string_literal: true

require 'rbs'

module Solargraph
  module RbsMap
    # Ruby stdlib pins
    #
    class Stdlib < Base
      # @param library [String]
      def initialize library
        super()
        # @sg-ignore Library method has no usable type
        loader.add(library: library.gsub('/', '-')) if self.class.has?(library)
      end

      def repository
        @repository ||= RBS::Repository.new(no_stdlib: false)
      end

      # @param library [String]
      def self.has? library
        # @sg-ignore https://github.com/castwide/solargraph/pull/1223
        !!RBS::Collection::Sources::Stdlib.instance.has?(library.gsub('/', '-'), nil)
      end
    end
  end
end
