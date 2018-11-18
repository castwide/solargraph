module Solargraph
  class SourceMap
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Base,           'solargraph/source_map/node_processor/base'
      autoload :BeginNode,      'solargraph/source_map/node_processor/begin_node'
      autoload :DefNode,        'solargraph/source_map/node_processor/def_node'
      autoload :DefsNode,       'solargraph/source_map/node_processor/defs_node'
      autoload :SendNode,       'solargraph/source_map/node_processor/send_node'
      autoload :NamespaceNode,  'solargraph/source_map/node_processor/namespace_node'
      autoload :SclassNode,     'solargraph/source_map/node_processor/sclass_node'
      autoload :ModuleNode,     'solargraph/source_map/node_processor/module_node'
      autoload :IvasgnNode,     'solargraph/source_map/node_processor/ivasgn_node'
      autoload :CvasgnNode,     'solargraph/source_map/node_processor/cvasgn_node'
      autoload :LvasgnNode,     'solargraph/source_map/node_processor/lvasgn_node'
      autoload :GvasgnNode,     'solargraph/source_map/node_processor/gvasgn_node'
      autoload :CasgnNode,      'solargraph/source_map/node_processor/casgn_node'
      autoload :AliasNode,      'solargraph/source_map/node_processor/alias_node'
      autoload :ArgsNode,       'solargraph/source_map/node_processor/args_node'
      autoload :BlockNode,      'solargraph/source_map/node_processor/block_node'
      autoload :OrasgnNode,     'solargraph/source_map/node_processor/orasgn_node'
      autoload :SymNode,        'solargraph/source_map/node_processor/sym_node'

      class << self
        @@processors ||= {}

        private

        def register node, cls
          @@processors[node] = cls
        end
      end

      register :source, BeginNode
      register :begin, BeginNode
      register :kwbegin, BeginNode
      # # @todo Is this the best way to handle rescue nodes?
      register :rescue, BeginNode
      register :resbody, BeginNode
      register :def, DefNode
      register :defs, DefsNode
      register :send, SendNode
      register :class, NamespaceNode
      register :module, NamespaceNode
      register :sclass, SclassNode
      register :ivasgn, IvasgnNode
      register :cvasgn, CvasgnNode
      register :lvasgn, LvasgnNode
      register :gvasgn, GvasgnNode
      register :casgn, CasgnNode
      register :alias, AliasNode
      register :args, ArgsNode
      register :block, BlockNode
      register :or_asgn, OrasgnNode
      register :sym, SymNode

      module_function

      # @param node [Parser::AST::Node]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def process node, region = Region.new(nil, '', :instance, :public, []), pins = []
        pins.push Pin::Namespace.new(region.source.location, '', '', nil, :class, :public) if pins.empty?
        return pins unless node.is_a?(Parser::AST::Node) && @@processors.key?(node.type)
        processor = @@processors[node.type].new(node, region, pins)
        processor.process
        processor.pins
      end
    end
  end
end
