# frozen_string_literal: true

require 'rbs'

module Solargraph
  module RbsMap
    # Ruby stdlib pins
    #
    class Stdlib < Base
      def initialize library
        super()
        # @sg-ignore https://github.com/castwide/solargraph/pull/1451
        #   also needs https://github.com/castwide/solargraph/pull/1240
        loader.add(library: library.gsub('/', '-'), version: nil) if self.class.has?(library)
      end

      def repository
        @repository ||= RBS::Repository.new(no_stdlib: false)
      end

      def self.has? library
        !!RBS::Collection::Sources::Stdlib.instance.has?(library.gsub('/', '-'), nil)
      end
    end
  end
end
