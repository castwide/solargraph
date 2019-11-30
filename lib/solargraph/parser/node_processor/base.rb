# frozen_string_literal: true

module Solargraph
  module Parser
    module NodeProcessor
      class Base
        # @todo The base node processor should not include legacy node methods
        # include Legacy::NodeMethods

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @return [Array<Pin::Base>]
        attr_reader :pins

        # @return [Array<Pin::Base>]
        attr_reader :locals

        # @param node [Parser::AST::Node]
        # @param region [Region]
        # @param pins [Array<Pin::Base>]
        def initialize node, region, pins, locals
          @node = node
          @region = region
          @pins = pins
          @locals = locals
        end

        # Subclasses should override this method to generate new pins.
        #
        # @return [void]
        def process
          process_children
        end

        private

        # @param subregion [Region]
        # @return [void]
        def process_children subregion = region
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

        def comments_for(node)
          region.source.comments_for(node)
        end

        def named_path_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.path && !pin.path.empty? && pin.location.range.contain?(position)}.last
        end

        # @todo Candidate for deprecation
        def block_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position)}.last
        end

        # @todo Candidate for deprecation
        def closure_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position)}.last
        end
      end
    end
  end
end
