# frozen_string_literal: true

require 'solargraph/parser/node_processor'

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        autoload :BeginNode,     'solargraph/parser/parser_gem/node_processors/begin_node'
        autoload :DefNode,       'solargraph/parser/parser_gem/node_processors/def_node'
        autoload :DefsNode,      'solargraph/parser/parser_gem/node_processors/defs_node'
        autoload :SendNode,      'solargraph/parser/parser_gem/node_processors/send_node'
        autoload :NamespaceNode, 'solargraph/parser/parser_gem/node_processors/namespace_node'
        autoload :SclassNode,    'solargraph/parser/parser_gem/node_processors/sclass_node'
        autoload :ModuleNode,    'solargraph/parser/parser_gem/node_processors/module_node'
        autoload :IvasgnNode,    'solargraph/parser/parser_gem/node_processors/ivasgn_node'
        autoload :CvasgnNode,    'solargraph/parser/parser_gem/node_processors/cvasgn_node'
        autoload :LvasgnNode,    'solargraph/parser/parser_gem/node_processors/lvasgn_node'
        autoload :GvasgnNode,    'solargraph/parser/parser_gem/node_processors/gvasgn_node'
        autoload :CasgnNode,     'solargraph/parser/parser_gem/node_processors/casgn_node'
        autoload :AliasNode,     'solargraph/parser/parser_gem/node_processors/alias_node'
        autoload :ArgsNode,      'solargraph/parser/parser_gem/node_processors/args_node'
        autoload :BlockNode,     'solargraph/parser/parser_gem/node_processors/block_node'
        autoload :OrasgnNode,    'solargraph/parser/parser_gem/node_processors/orasgn_node'
        autoload :SymNode,       'solargraph/parser/parser_gem/node_processors/sym_node'
        autoload :ResbodyNode,   'solargraph/parser/parser_gem/node_processors/resbody_node'
      end
    end

    module NodeProcessor
      register :source,       ParserGem::NodeProcessors::BeginNode
      register :begin,        ParserGem::NodeProcessors::BeginNode
      register :kwbegin,      ParserGem::NodeProcessors::BeginNode
      register :rescue,       ParserGem::NodeProcessors::BeginNode
      register :resbody,      ParserGem::NodeProcessors::ResbodyNode
      register :def,          ParserGem::NodeProcessors::DefNode
      register :defs,         ParserGem::NodeProcessors::DefsNode
      register :send,         ParserGem::NodeProcessors::SendNode
      register :class,        ParserGem::NodeProcessors::NamespaceNode
      register :module,       ParserGem::NodeProcessors::NamespaceNode
      register :sclass,       ParserGem::NodeProcessors::SclassNode
      register :ivasgn,       ParserGem::NodeProcessors::IvasgnNode
      register :cvasgn,       ParserGem::NodeProcessors::CvasgnNode
      register :lvasgn,       ParserGem::NodeProcessors::LvasgnNode
      register :gvasgn,       ParserGem::NodeProcessors::GvasgnNode
      register :casgn,        ParserGem::NodeProcessors::CasgnNode
      register :alias,        ParserGem::NodeProcessors::AliasNode
      register :args,         ParserGem::NodeProcessors::ArgsNode
      register :forward_args, ParserGem::NodeProcessors::ArgsNode
      register :block,        ParserGem::NodeProcessors::BlockNode
      register :or_asgn,      ParserGem::NodeProcessors::OrasgnNode
      register :sym,          ParserGem::NodeProcessors::SymNode
    end
  end
end
