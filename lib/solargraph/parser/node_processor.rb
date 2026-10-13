# frozen_string_literal: true

module Solargraph
  module Parser
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Base, 'solargraph/parser/node_processor/base'

      class << self
        # @type [Hash{Symbol => Array<Class<NodeProcessor::Base>>}]
        @@processors ||= {}

        # Register a processor for a node type. You can register multiple processors for the same type.
        # If a node processor returns true, it will skip the next processor of the same node type.
        #
        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        # @return [Array<Class<NodeProcessor::Base>>]
        # @sg-ignore flow sensitive typing needs to track reassignment
        def register type, cls
          @@processors[type] ||= []
          # @sg-ignore flow sensitive typing needs to track reassignment
          @@processors[type] << cls
        end

        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        #
        # @return [void]
        def deregister type, cls
          # @sg-ignore https://github.com/castwide/solargraph/pull/1245
          @@processors[type].delete(cls)
        end
      end

      # @param node [Parser::AST::Node, nil]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @param locals [Array<Pin::LocalVariable>]
      # @param ivars [Array<Pin::InstanceVariable>]
      # @return [Array(Array<Pin::Base>, Array<Pin::LocalVariable>, Array<Pin::InstanceVariable>)]
      def self.process node, region = Region.new, pins = [], locals = [], ivars = []
        if pins.empty?
          pins.push Pin::Namespace.new(
            location: region.source.location,
            name: '',
            source: :parser
          )
        end
        return [pins, locals, ivars] unless Parser.is_ast_node?(node)
        # @sg-ignore https://github.com/castwide/solargraph/pull/1396
        node_processor_classes = @@processors[node.type] || [NodeProcessor::Base]

        node_processor_classes.each do |klass|
          # @sg-ignore https://github.com/castwide/solargraph/pull/1396
          processor = klass.new(node, region, pins, locals, ivars)
          process_next = processor.process

          break unless process_next
        end

        [pins, locals, ivars]
      end
    end
  end
end
