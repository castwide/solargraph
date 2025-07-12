# frozen_string_literal: true

module Solargraph
  module Parser
    module NodeProcessor
      class Base
        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @return [Array<Pin::Base>]
        attr_reader :pins

        # @return [Array<Pin::BaseVariable>]
        attr_reader :locals

        # @param node [Parser::AST::Node]
        # @param region [Region]
        # @param pins [Array<Pin::Base>]
        # @param locals [Array<Pin::LocalVariable>]
        def initialize node, region, pins, locals
          @node = node
          @region = region
          @pins = pins
          @locals = locals
          @processed_children = false
        end

        # Subclasses should override this method to generate new pins.
        #
        # @return [Boolean] continue processing the next processor of the same node type.
        # @return [void] In case there is only one processor registered for the node type, it can be void.
        def process
          process_children

          true
        end

        private

        # @param subregion [Region]
        # @return [void]
        def process_children subregion = region
          return if @processed_children
          @processed_children = true
          node.children.each do |child|
            next unless Parser.is_ast_node?(child)
            NodeProcessor.process(child, subregion, pins, locals)
          end
        end

        # @param node [Parser::AST::Node]
        # @return [Solargraph::Location]
        def get_node_location(node)
          range = Parser.node_range(node)
          Location.new(region.filename, range)
        end

        # @param node [Parser::AST::Node]
        # @return [String, nil]
        def comments_for(node)
          region.source.comments_for(node)
        end

        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def named_path_pin position
          pins.select do |pin|
            pin.is_a?(Pin::Closure) && pin.path && !pin.path.empty? && pin.location.range.contain?(position)
          end.last
        end

        # @todo Candidate for deprecation
        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def block_pin position
          # @todo determine if this can return a Pin::Block
          pins.select { |pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position) }.last
        end

        # @todo Candidate for deprecation
        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def closure_pin position
          pins.select { |pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
