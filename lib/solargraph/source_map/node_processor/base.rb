module Solargraph
  class SourceMap
    module NodeProcessor
      class Base
        include Solargraph::Source::NodeMethods

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Context]
        attr_reader :context

        # @param node [Parser::AST::Node]
        # @param context [Context]
        def initialize node, context
          @node = node
          @context = context
        end

        # Subclasses should override this method to return the generated pins
        # and resulting context.
        #
        # @return [Array<Pin::Base>]
        def process
          raise NoMethodError, "#{self.class} does not implement the `process` method"
        end

        private

        def process_children subcontext = context
          result = []
          node.children.each do |child|
            next unless child.is_a?(Parser::AST::Node)
            result.concat Processors.process(child, subcontext)
          end
          result
        end
      end
    end
  end
end
