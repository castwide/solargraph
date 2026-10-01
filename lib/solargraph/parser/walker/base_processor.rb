# frozen_string_literal: true

require 'rubocop-ast'

module Solargraph
  module Parser
    class Walker
      # Base class for processors that hook into a {Walker}. Subclasses
      # register handlers for node types or node patterns; the walker creates
      # one processor instance per node it dispatches to.
      #
      class BaseProcessor
        extend RuboCop::AST::NodePattern::Macros

        class << self
          # @param type [Symbol]
          # @param method_name [Symbol, nil] the handler method, or nil to use the block
          # @return [void]
          def on_node_type type, method_name = nil, &block
            Walker.register(:enter, self, method_name || block, type: type)
          end

          # @param type [Symbol]
          # @param method_name [Symbol, nil] the handler method, or nil to use the block
          # @return [void]
          def on_node_type_leave type, method_name = nil, &block
            Walker.register(:leave, self, method_name || block, type: type)
          end

          # The handler receives the pattern's captures as arguments.
          #
          # @param pattern [String] a RuboCop::AST::NodePattern
          # @param method_name [Symbol, nil] the handler method, or nil to use the block
          # @return [void]
          def on_node_pattern_enter pattern, method_name = nil, &block
            Walker.register(:enter, self, method_name || block, pattern: pattern)
          end

          # @param pattern [String] a RuboCop::AST::NodePattern
          # @param method_name [Symbol, nil] the handler method, or nil to use the block
          # @return [void]
          def on_node_pattern_leave pattern, method_name = nil, &block
            Walker.register(:leave, self, method_name || block, pattern: pattern)
          end
        end

        # @return [Walker]
        attr_reader :walker

        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @param walker [Walker]
        def initialize walker
          @walker = walker
          @node = walker.node
          @region = walker.region
        end

        # @param callback [Symbol, Proc]
        # @param captures [Array]
        # @return [void]
        def handle callback, captures
          if callback.is_a?(Proc)
            instance_exec(*captures, &callback)
          else
            send(callback, *captures)
          end
        end

        private

        # @param subregion [Region]
        # @return [void]
        def process_children subregion = region
          walker.process_children(subregion)
        end

        # @return [void]
        def skip_children
          walker.skip_children
        end

        # @param node [::Parser::AST::Node, nil]
        # @param subregion [Region]
        # @return [void]
        def walk node, subregion = region
          walker.walk(node, subregion)
        end
      end
    end
  end
end
