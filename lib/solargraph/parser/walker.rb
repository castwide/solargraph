# frozen_string_literal: true

require 'rubocop-ast'

module Solargraph
  module Parser
    # Walks an AST once, dispatching enter and leave events for each node to
    # the handlers that processors register by node type or node pattern.
    class Walker
      autoload :BaseProcessor, 'solargraph/parser/walker/base_processor'

      class Handler
        # @return [Class<BaseProcessor>]
        attr_reader :processor_class

        # @return [Symbol, Proc]
        attr_reader :callback

        # @return [Array<Symbol>, nil] nil if the handler can match any node type
        attr_reader :types

        # @param processor_class [Class<BaseProcessor>]
        # @param callback [Symbol, Proc]
        # @param type [Symbol, nil]
        # @param pattern [String, nil]
        def initialize processor_class, callback, type: nil, pattern: nil
          @processor_class = processor_class
          @callback = callback
          @pattern = pattern && RuboCop::AST::NodePattern.new(pattern)
          @types = @pattern ? root_types(@pattern.ast) : [type]
        end

        # @param type [Symbol]
        # @return [Boolean]
        def applies_to? type
          node_types = types
          node_types.nil? || node_types.include?(type)
        end

        # @param node [::Parser::AST::Node]
        # @return [Array, nil] the pattern's captures, or nil if the node does not match
        def match node
          return [] unless @pattern

          @pattern.match(node) { |*captures| captures }
        end

        private

        # @param ast [RuboCop::AST::NodePattern::Node]
        # @return [Array<Symbol>, nil]
        def root_types ast
          case ast.type
          when :sequence
            # @type [RuboCop::AST::NodePattern::Node]
            head = ast.children.fetch(0)
            [head.child] if head.type == :node_type
          when :capture
            root_types(ast.child)
          when :union
            types = ast.children.map { |branch| root_types(branch) }
            types.flatten if types.all?
          end
        end
      end
      private_constant :Handler

      class Frame
        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @return [Boolean]
        attr_accessor :children_processed

        # @return [Boolean]
        attr_accessor :halted

        # @param node [::Parser::AST::Node]
        # @param region [Region]
        def initialize node, region
          @node = node
          @region = region
          @children_processed = false
          @halted = false
          # @type [Hash{Class<BaseProcessor> => BaseProcessor}]
          @processors = {}
        end

        # @param processor_class [Class<BaseProcessor>]
        # @param walker [Walker]
        # @return [BaseProcessor]
        def processor processor_class, walker
          @processors[processor_class] ||= processor_class.new(walker)
        end
      end
      private_constant :Frame

      class << self
        # @param event [Symbol] :enter or :leave
        # @param processor_class [Class<BaseProcessor>]
        # @param callback [Symbol, Proc]
        # @param type [Symbol, nil]
        # @param pattern [String, nil]
        # @return [void]
        def register event, processor_class, callback, type: nil, pattern: nil
          handlers_of(event) << Handler.new(processor_class, callback, type: type, pattern: pattern)
          @dispatch_tables = nil
        end

        # @param processor_class [Class<BaseProcessor>]
        # @param type [Symbol, nil] only remove the processor's handlers for this node type
        # @return [void]
        def deregister processor_class, type = nil
          handlers.each_value do |list|
            list.reject! { |h| h.processor_class == processor_class && (type.nil? || h.types == [type]) }
          end
          @dispatch_tables = nil
        end

        # @param event [Symbol]
        # @param type [Symbol]
        # @return [Array<Handler>]
        def handlers_for event, type
          table = dispatch_tables[event] ||= {}
          table[type] ||= handlers_of(event).select { |handler| handler.applies_to?(type) }
        end

        private

        # @return [Hash{Symbol => Array<Handler>}]
        def handlers
          @handlers ||= { enter: [], leave: [] }
        end

        # @param event [Symbol]
        # @return [Array<Handler>]
        def handlers_of event
          handlers[event] || []
        end

        # @return [Hash{Symbol => Hash{Symbol => Array<Handler>}}]
        def dispatch_tables
          @dispatch_tables ||= {}
        end
      end

      # @return [Array<Pin::Base>]
      attr_reader :pins

      # @return [Array<Pin::LocalVariable>]
      attr_reader :locals

      # @return [Array<Pin::InstanceVariable>]
      attr_reader :ivars

      # @param ast [::Parser::AST::Node, nil]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @param locals [Array<Pin::LocalVariable>]
      # @param ivars [Array<Pin::InstanceVariable>]
      def initialize ast, region: Region.new, pins: [], locals: [], ivars: []
        @ast = ast
        @region = region
        @pins = pins
        @locals = locals
        @ivars = ivars
        # @type [Array<Frame>]
        @frames = []
      end

      # Shared state that lets processors cooperate without referencing each other.
      #
      # @return [Hash]
      def context
        @context ||= {}
      end

      # @return [void]
      def on_after_walk &block
        after_walk_handlers << block
      end

      # @return [void]
      def walk!
        walk(@ast, @region)
        after_walk_handlers.each(&:call)
      end

      # @param node [::Parser::AST::Node, nil]
      # @param region [Region]
      # @return [void]
      def walk node, region = self.region
        return if node.nil?

        frame = Frame.new(node, region)
        @frames.push frame
        dispatch :enter, frame
        process_children unless frame.children_processed
        dispatch :leave, frame
        @frames.pop
      end

      # @return [::Parser::AST::Node]
      def node
        current_frame.node
      end

      # @return [Region]
      def region
        @frames.empty? ? @region : current_frame.region
      end

      # Walk the current node's children, unless they have already been walked or skipped.
      #
      # @param subregion [Region]
      # @return [Array, nil]
      def process_children subregion = region
        frame = current_frame
        return if frame.children_processed

        frame.children_processed = true
        frame.node.children.each { |child| walk(child, subregion) if child.is_a?(::Parser::AST::Node) }
      end

      # @return [void]
      def skip_children
        current_frame.children_processed = true
      end

      # Stop dispatching the current node to the remaining enter handlers.
      #
      # @return [void]
      def halt
        current_frame.halted = true
      end

      private

      # @return [Frame]
      def current_frame
        @frames.fetch(-1)
      end

      # @return [Array<Proc>]
      def after_walk_handlers
        @after_walk_handlers ||= []
      end

      # @param event [Symbol]
      # @param frame [Frame]
      # @return [void]
      def dispatch event, frame
        Walker.handlers_for(event, frame.node.type).each do |handler|
          break if event == :enter && frame.halted

          captures = handler.match(frame.node)
          next unless captures

          frame.processor(handler.processor_class, self).handle(handler.callback, captures)
        end
      end
    end
  end
end
