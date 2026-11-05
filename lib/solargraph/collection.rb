# frozen_string_literal: true

module Solargraph
  module Collection
    autoload :Base,   'solargraph/collection/base'
    autoload :Core,   'solargraph/collection/core'
    autoload :Gem,    'solargraph/collection/gem'
    autoload :Stdlib, 'solargraph/collection/stdlib'

    # A hash for storing pin collections in memory.
    #
    # @return [Hash{String => Array<Pin::Base>}]
    def self.mem_cache
      @mem_cache ||= {}
    end

    # The pins cached under a key, storing the block result on a miss.
    #
    # @param key [String]
    # @return [Array<Pin::Base>]
    def self.cached key
      mem_cache.fetch(key) { mem_cache[key] = yield }
    end

    # @return [void]
    def self.clear_mem_cache
      mem_cache.clear
    end
  end
end
