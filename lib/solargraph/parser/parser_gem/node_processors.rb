# frozen_string_literal: true

require 'solargraph/parser/node_processor'

module Solargraph
  module Parser
    module NodeProcessor
      # Registered before the processors below so they can halt the generic class and constant processors
      register :class,        Convention::StructDefinition::NodeProcessors::StructNode
      register :class,        Convention::DataDefinition::NodeProcessors::DataNode
      register :casgn,        Convention::StructDefinition::NodeProcessors::StructNode
      register :casgn,        Convention::DataDefinition::NodeProcessors::DataNode
    end
  end
end

require 'solargraph/parser/parser_gem/node_processors/alias_node'
require 'solargraph/parser/parser_gem/node_processors/and_node'
require 'solargraph/parser/parser_gem/node_processors/args_node'
require 'solargraph/parser/parser_gem/node_processors/block_node'
require 'solargraph/parser/parser_gem/node_processors/casgn_node'
require 'solargraph/parser/parser_gem/node_processors/cvasgn_node'
require 'solargraph/parser/parser_gem/node_processors/def_node'
require 'solargraph/parser/parser_gem/node_processors/defs_node'
require 'solargraph/parser/parser_gem/node_processors/gvasgn_node'
require 'solargraph/parser/parser_gem/node_processors/if_node'
require 'solargraph/parser/parser_gem/node_processors/ivasgn_node'
require 'solargraph/parser/parser_gem/node_processors/lvasgn_node'
require 'solargraph/parser/parser_gem/node_processors/masgn_node'
require 'solargraph/parser/parser_gem/node_processors/namespace_node'
require 'solargraph/parser/parser_gem/node_processors/opasgn_node'
require 'solargraph/parser/parser_gem/node_processors/or_node'
require 'solargraph/parser/parser_gem/node_processors/orasgn_node'
require 'solargraph/parser/parser_gem/node_processors/resbody_node'
require 'solargraph/parser/parser_gem/node_processors/sclass_node'
require 'solargraph/parser/parser_gem/node_processors/send_node'
require 'solargraph/parser/parser_gem/node_processors/sym_node'
require 'solargraph/parser/parser_gem/node_processors/until_node'
require 'solargraph/parser/parser_gem/node_processors/when_node'
require 'solargraph/parser/parser_gem/node_processors/while_node'
