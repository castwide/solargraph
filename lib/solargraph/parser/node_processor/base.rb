# frozen_string_literal: true

module Solargraph
  module Parser
    module NodeProcessor
      class Base < Walker::BaseProcessor
        # @return [Array<Pin::Base>]
        def pins
          walker.pins
        end

        # @return [Array<Pin::LocalVariable>]
        def locals
          walker.locals
        end

        # @return [Array<Pin::InstanceVariable>]
        def ivars
          walker.ivars
        end

        # Processors registered with {NodeProcessor.register} override this method to generate new pins.
        #
        # @return [Boolean] continue processing the next processor of the same node type.
        # @return [void] In case there is only one processor registered for the node type, it can be void.
        def process
          process_children

          true
        end

        # @return [void]
        def process_or_halt
          walker.halt unless process
        end

        private

        # @return [Solargraph::Location]
        def location
          get_node_location(node)
        end

        # @return [Solargraph::Position]
        def position
          Position.new(node.loc.line, node.loc.column)
        end

        # @sg-ignore downcast output of Enumerable#select
        # @return [Solargraph::Pin::Breakable, nil]
        def enclosing_breakable_pin
          pins.select { |pin| pin.is_a?(Pin::Breakable) && pin.location&.range&.contain?(position) }.last
        end

        # @todo downcast output of Enumerable#select
        # @return [Solargraph::Pin::CompoundStatement, nil]
        def enclosing_compound_statement_pin
          pins.select { |pin| pin.is_a?(Pin::CompoundStatement) && pin.location&.range&.contain?(position) }.last
        end

        # @param node [Parser::AST::Node]
        # @return [Solargraph::Location]
        def get_node_location node
          range = Parser.node_range(node)
          Location.new(region.filename, range)
        end

        # @param node [Parser::AST::Node]
        # @return [String, nil]
        def comments_for node
          region.source.comments_for(node)
        end

        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def named_path_pin position
          pins.select do |pin|
            # @sg-ignore Need to add nil check here
            pin.is_a?(Pin::Closure) && pin.path && !pin.path.empty? && pin.location.range.contain?(position)
          end.last
        end

        # @todo Candidate for deprecation
        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def block_pin position
          # @todo determine if this can return a Pin::Block
          # @sg-ignore Need to add nil check here
          pins.select { |pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position) }.last
        end

        # @todo Candidate for deprecation
        # @param position [Solargraph::Position]
        # @return [Pin::Closure, nil]
        def closure_pin position
          # @sg-ignore Need to add nil check here
          pins.select { |pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
