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
        # @param context [Context]
        def initialize node, region, pins
          @node = node
          @region = region
          @pins = pins
        end

        protected

        # Subclasses should override this method to return the generated pins
        # and resulting context.
        #
        # @return [Array<Pin::Base>]
        def process
          raise NoMethodError, "#{self.class} does not implement the `process` method"
        end

        private

        def process_children subregion = region
          result = []
          node.children.each do |child|
            next unless child.is_a?(Parser::AST::Node)
            result.concat NodeProcessor.process(child, subregion)
          end
          pins.concat result
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
      end
    end
  end
end
