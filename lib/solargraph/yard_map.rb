# frozen_string_literal: true

require 'yard'
require 'solargraph/yard_tags'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    class NoYardocError < StandardError; end

    autoload :Cache,       'solargraph/yard_map/cache'
    autoload :Mapper,      'solargraph/yard_map/mapper'
    autoload :Helpers,     'solargraph/yard_map/helpers'
    autoload :ToMethod,    'solargraph/yard_map/to_method'
  end
end
