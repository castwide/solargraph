# frozen_string_literal: true

module Solargraph
  module Parser
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Base, 'solargraph/parser/node_processor/base'

      class << self
        # Register a processor's #process method for a node type. You can register multiple processors for the same
        # type. If a processor's #process returns a falsy value, the next processors of the same node type are skipped.
        #
        # Processors can also register their own handlers with {Walker::BaseProcessor.on_node_type} and
        # {Walker::BaseProcessor.on_node_pattern_enter}.
        #
        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        # @return [void]
        def register type, cls
          cls.on_node_type(type, :process_or_halt)
        end

        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        #
        # @return [void]
        def deregister type, cls
          Walker.deregister(cls, type)
        end
      end

      # @param node [Parser::AST::Node]
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

        Walker.new(node, region: region, pins: pins, locals: locals, ivars: ivars).walk!

        [pins, locals, ivars]
      end
    end
  end
end
