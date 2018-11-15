module Solargraph
  class SourceMap
    module NodeProcessor
      class Base
        include Solargraph::Source::NodeMethods

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @return [Array<Pin::Base>]
        attr_reader :pins

        # @param node [Parser::AST::Node]
        # @param region [Region]
        # @param pins [Array<Pin::Base>]
        def initialize node, region, pins
          @node = node
          @region = region
          @pins = pins
        end

        protected

        # Subclasses should override this method to generate new pins.
        #
        # @return [Array<Pin::Base>]
        def process
          raise NoMethodError, "#{self.class} does not implement the `process` method"
        end

        private

        def process_children subregion = region
          node.children.each do |child|
            next unless child.is_a?(Parser::AST::Node)
            NodeProcessor.process(child, subregion, pins)
          end
        end

        # @param node [Parser::AST::Node]
        # @return [Solargraph::Location]
        def get_node_location(node)
          if node.nil?
            st = Position.new(0, 0)
            en = Position.from_offset(@code, @code.length)
          else
            st = Position.new(node.loc.line, node.loc.column)
            en = Position.new(node.loc.last_line, node.loc.last_column)
          end
          range = Range.new(st, en)
          Location.new(region.filename, range)
        end

        def comments_for(node)
          ''
        end

        def named_path_pin position
          pins.select{|pin| [Pin::NAMESPACE, Pin::METHOD].include?(pin.kind) and pin.location.range.contain?(position)}.last
        end

        def block_pin position
          pins.select{|pin| [Pin::BLOCK, Pin::NAMESPACE, Pin::METHOD].include?(pin.kind) and pin.location.range.contain?(position)}.last
        end  
      end
    end
  end
end
