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
        autoload :IvasgnNode,    'solargraph/parser/parser_gem/node_processors/ivasgn_node'
        autoload :IfNode,        'solargraph/parser/parser_gem/node_processors/if_node'
        autoload :CvasgnNode,    'solargraph/parser/parser_gem/node_processors/cvasgn_node'
        autoload :LvasgnNode,    'solargraph/parser/parser_gem/node_processors/lvasgn_node'
        autoload :GvasgnNode,    'solargraph/parser/parser_gem/node_processors/gvasgn_node'
        autoload :CasgnNode,     'solargraph/parser/parser_gem/node_processors/casgn_node'
        autoload :MasgnNode,     'solargraph/parser/parser_gem/node_processors/masgn_node'
        autoload :AliasNode,     'solargraph/parser/parser_gem/node_processors/alias_node'
        autoload :ArgsNode,      'solargraph/parser/parser_gem/node_processors/args_node'
        autoload :BlockNode,     'solargraph/parser/parser_gem/node_processors/block_node'
        autoload :OrasgnNode,    'solargraph/parser/parser_gem/node_processors/orasgn_node'
        autoload :OpasgnNode,    'solargraph/parser/parser_gem/node_processors/opasgn_node'
        autoload :SymNode,       'solargraph/parser/parser_gem/node_processors/sym_node'
        autoload :ResbodyNode,   'solargraph/parser/parser_gem/node_processors/resbody_node'
        autoload :UntilNode,     'solargraph/parser/parser_gem/node_processors/until_node'
        autoload :WhileNode,     'solargraph/parser/parser_gem/node_processors/while_node'
        autoload :AndNode,       'solargraph/parser/parser_gem/node_processors/and_node'
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
      register :if,           ParserGem::NodeProcessors::IfNode
      register :send,         ParserGem::NodeProcessors::SendNode
      register :class,        Convention::StructDefinition::NodeProcessors::StructNode
      register :class,        Convention::DataDefinition::NodeProcessors::DataNode
      register :class,        ParserGem::NodeProcessors::NamespaceNode
      register :module,       ParserGem::NodeProcessors::NamespaceNode
      register :sclass,       ParserGem::NodeProcessors::SclassNode
      register :ivasgn,       ParserGem::NodeProcessors::IvasgnNode
      register :cvasgn,       ParserGem::NodeProcessors::CvasgnNode
      register :lvasgn,       ParserGem::NodeProcessors::LvasgnNode
      register :gvasgn,       ParserGem::NodeProcessors::GvasgnNode
      register :casgn,        Convention::StructDefinition::NodeProcessors::StructNode
      register :casgn,        Convention::DataDefinition::NodeProcessors::DataNode
      register :casgn,        ParserGem::NodeProcessors::CasgnNode
      register :masgn,        ParserGem::NodeProcessors::MasgnNode
      register :alias,        ParserGem::NodeProcessors::AliasNode
      register :args,         ParserGem::NodeProcessors::ArgsNode
      register :forward_args, ParserGem::NodeProcessors::ArgsNode
      register :block,        ParserGem::NodeProcessors::BlockNode
      register :or_asgn,      ParserGem::NodeProcessors::OrasgnNode
      register :op_asgn,      ParserGem::NodeProcessors::OpasgnNode
      register :sym,          ParserGem::NodeProcessors::SymNode
      register :until,        ParserGem::NodeProcessors::UntilNode
      register :while,        ParserGem::NodeProcessors::WhileNode
      register :and,          ParserGem::NodeProcessors::AndNode
    end
  end
end
