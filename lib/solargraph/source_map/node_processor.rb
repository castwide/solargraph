module Solargraph
  class SourceMap
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Context,    'solargraph/source_map/node_processor/context'
      autoload :Base,       'solargraph/source_map/node_processor/base'
      autoload :BeginNode, 'solargraph/source_map/node_processor/begin_node'
      autoload :DefNode,    'solargraph/source_map/node_processor/def_node'
      autoload :DefsNode,   'solargraph/source_map/node_processor/defs_node'
      autoload :SendNode,   'solargraph/source_map/node_processor/send_node'
      autoload :ClassNode,  'solargraph/source_map/node_processor/class_node'
      autoload :SclassNode, 'solargraph/source_map/node_processor/sclass_node'
      autoload :ModuleNode, 'solargraph/source_map/node_processor/module_node'
      autoload :IvasgnNode, 'solargraph/source_map/node_processor/ivasgn_node'
      autoload :CvasgnNode, 'solargraph/source_map/node_processor/cvasgn_node'
      autoload :LvasgnNode, 'solargraph/source_map/node_processor/lvasgn_node'
      autoload :GvasgnNode, 'solargraph/source_map/node_processor/gvasgn_node'
      autoload :CasgnNode,  'solargraph/source_map/node_processor/casgn_node'
      autoload :AliasNode,  'solargraph/source_map/node_processor/alias_node'
      autoload :ArgsNode,   'solargraph/source_map/node_processor/args_node'
      autoload :BlockNode,  'solargraph/source_map/node_processor/block_node'
      autoload :OrasgnNode, 'solargraph/source_map/node_processor/orasgn_node'

      class << self
        @@processors ||= {}

        private

        def register node, cls
          @@processors[node] = cls
        end
      end

      register :source, BeginNode
      register :begin, BeginNode
      register :def, DefNode
      register :defs, DefsNode
      register :send, SendNode
      register :class, ClassNode
      register :sclass, SclassNode
      # @todo Smelly names
      register :module, ClassNode
      register :ivasgn, IvasgnNode
      register :cvasgn, CvasgnNode
      register :lvasgn, LvasgnNode
      register :gvasgn, GvasgnNode
      register :casgn, CasgnNode
      register :alias, AliasNode
      register :args, ArgsNode
      register :block, BlockNode
      register :or_asgn, OrasgnNode

      module_function

      # @param node [Parser::AST::Node]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @param stack [Array<Parser::AST::Node]
      # @return [Array<Pin::Base>]
      def process node, region = Region.new(nil, '', :instance, :public, []), pins = [], stack = []
        return [] unless @@processors.key?(node.type)
        processor = @@processors[node.type].new(node, region, pins, stack)
        processor.process
        processor.pins
      end
    end
  end
end
