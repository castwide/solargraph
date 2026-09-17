# frozen_string_literal: true

require 'rbs'

module Solargraph
  module RbsMap
    autoload :Base,        'solargraph/rbs_map/base'
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :Core,        'solargraph/rbs_map/core'
    autoload :CoreFills,   'solargraph/rbs_map/core_fills'
    autoload :Gem,         'solargraph/rbs_map/gem'
    autoload :Path,        'solargraph/rbs_map/path'
    autoload :Stdlib,      'solargraph/rbs_map/stdlib'
  end
end
