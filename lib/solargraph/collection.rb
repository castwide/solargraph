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
  end
end
