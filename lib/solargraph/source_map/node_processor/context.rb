module Solargraph
  class SourceMap
    module NodeProcessor
      class Context
        attr_reader :stack
        attr_reader :namespace
        attr_reader :scope
        attr_reader :visibility

        def initialize namespace, scope, visibility
          @stack = []
          @namespace = namespace
          @scope = scope
          @visibility = visibility
        end

        def update node: nil, namespace: nil, scope: nil, visibility: nil
          result = Context.new(
            namespace || self.namespace,
            scope || self.scope,
            visibility || self.visibility
          )
          result.stack = stack.clone
          result.stack.push node unless node.nil?
          result
        end

        protected

        attr_writer :stack

        ROOT = Context.new([], '', :class, :public)
      end
    end
  end
end
