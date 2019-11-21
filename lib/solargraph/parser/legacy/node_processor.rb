# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      # The processor classes used by SourceMap::Mapper to generate pins from
      # parser nodes.
      #
      module NodeProcessor
        autoload :Base,          'solargraph/parser/legacy/node_processor/base'
        autoload :BeginNode,     'solargraph/parser/legacy/node_processor/begin_node'
        autoload :DefNode,       'solargraph/parser/legacy/node_processor/def_node'
        autoload :DefsNode,      'solargraph/parser/legacy/node_processor/defs_node'
        autoload :SendNode,      'solargraph/parser/legacy/node_processor/send_node'
        autoload :NamespaceNode, 'solargraph/parser/legacy/node_processor/namespace_node'
        autoload :SclassNode,    'solargraph/parser/legacy/node_processor/sclass_node'
        autoload :ModuleNode,    'solargraph/parser/legacy/node_processor/module_node'
        autoload :IvasgnNode,    'solargraph/parser/legacy/node_processor/ivasgn_node'
        autoload :CvasgnNode,    'solargraph/parser/legacy/node_processor/cvasgn_node'
        autoload :LvasgnNode,    'solargraph/parser/legacy/node_processor/lvasgn_node'
        autoload :GvasgnNode,    'solargraph/parser/legacy/node_processor/gvasgn_node'
        autoload :CasgnNode,     'solargraph/parser/legacy/node_processor/casgn_node'
        autoload :AliasNode,     'solargraph/parser/legacy/node_processor/alias_node'
        autoload :ArgsNode,      'solargraph/parser/legacy/node_processor/args_node'
        autoload :BlockNode,     'solargraph/parser/legacy/node_processor/block_node'
        autoload :OrasgnNode,    'solargraph/parser/legacy/node_processor/orasgn_node'
        autoload :SymNode,       'solargraph/parser/legacy/node_processor/sym_node'
        autoload :ResbodyNode,   'solargraph/parser/legacy/node_processor/resbody_node'

        class << self
          @@processors ||= {}

          private

          # Register a processor for a node type.
          #
          # @param type [Symbol]
          # @param cls [Class<NodeProcessor::Base>]
          # @return [Class<NodeProcessor::Base>]
          def register type, cls
            @@processors[type] = cls
          end
        end

        register :source,  BeginNode
        register :begin,   BeginNode
        register :kwbegin, BeginNode
        register :rescue,  BeginNode
        register :resbody, ResbodyNode
        register :def,     DefNode
        register :defs,    DefsNode
        register :send,    SendNode
        register :class,   NamespaceNode
        register :module,  NamespaceNode
        register :sclass,  SclassNode
        register :ivasgn,  IvasgnNode
        register :cvasgn,  CvasgnNode
        register :lvasgn,  LvasgnNode
        register :gvasgn,  GvasgnNode
        register :casgn,   CasgnNode
        register :alias,   AliasNode
        register :args,    ArgsNode
        register :block,   BlockNode
        register :or_asgn, OrasgnNode
        register :sym,     SymNode

        # @param node [Parser::AST::Node]
        # @param region [Region]
        # @param pins [Array<Pin::Base>]
        # @return [Array(Array<Pin::Base>, Array<Pin::Base>)]
        def self.process node, region = Region.new, pins = [], locals = []
          if pins.empty?
            pins.push Pin::Namespace.new(
              location: region.source.location,
              name: ''
            )
          end
          return [pins, locals] unless node.is_a?(::Parser::AST::Node)
          klass = @@processors[node.type] || BeginNode
          processor = klass.new(node, region, pins, locals)
          processor.process
          [processor.pins, processor.locals]
        end
      end
    end
  end
end
