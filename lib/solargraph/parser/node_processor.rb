# frozen_string_literal: true

module Solargraph
  module Parser
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Base, 'solargraph/parser/node_processor/base'

      class << self
        # @type [Hash<Symbol, Array<Class<NodeProcessor::Base>>>]
        @@processors ||= {}

        # Register a processor for a node type. You can register multiple processors for the same type.
        # If a node processor returns true, it will skip the next processor of the same node type.
        #
        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        # @return [Class<NodeProcessor::Base>]
        def register type, cls
          @@processors[type] ||= []
          @@processors[type] << cls
        end

        def deregister type, cls
          @@processors[type].delete(cls)
        end
      end

      # @param node [Parser::AST::Node]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @param locals [Array<Pin::BaseVariable>]
      # @return [Array(Array<Pin::Base>, Array<Pin::Base>)]
      def self.process node, region = Region.new, pins = [], locals = []
        if pins.empty?
          pins.push Pin::Namespace.new(
            location: region.source.location,
            name: '',
            source: :parser,
          )
        end
        return [pins, locals] unless Parser.is_ast_node?(node)
        node_processor_classes = @@processors[node.type] || [NodeProcessor::Base]

        node_processor_classes.each do |klass|
          processor = klass.new(node, region, pins, locals)
          process_next = processor.process

          break unless process_next
        end

        [pins, locals]
      end
    end
  end
end
