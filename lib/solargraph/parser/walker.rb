# frozen_string_literal: true

require 'rubocop-ast'

module Solargraph
  module Parser
    # Walks an AST once, dispatching enter and leave events for each node to
    # the handlers that processors register by node type or node pattern.
    class Walker
      autoload :BaseProcessor, 'solargraph/parser/walker/base_processor'

      SEND_TYPES = %i[send csend].freeze
      private_constant :SEND_TYPES

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
          @method_names = @pattern && method_names(@pattern.ast)
        end

        # @param type [Symbol]
        # @param method_name [Symbol, nil] the method name of a send node
        # @return [Boolean]
        def applies_to? type, method_name
          node_types = types
          return false unless node_types.nil? || node_types.include?(type)

          names = @method_names
          names.nil? || names.include?(method_name)
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

        # The method names a send pattern is limited to, so other sends skip the match
        #
        # @param ast [RuboCop::AST::NodePattern::Node]
        # @return [Array<Symbol>, nil]
        def method_names ast
          return unless ast.type == :sequence && SEND_TYPES.include?(ast.children.fetch(0).child)

          method = ast.children[2]
          literal_symbols(method) if method
        end

        # @param ast [RuboCop::AST::NodePattern::Node]
        # @return [Array<Symbol>, nil]
        def literal_symbols ast
          case ast.type
          when :symbol
            [ast.child]
          when :capture
            literal_symbols(ast.child)
          when :set, :union
            # @type [Array<Array<Symbol>, nil>]
            symbols = ast.children.map { |branch| literal_symbols(branch) }
            symbols.flatten if symbols.all?
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
        end

        # @param processor_class [Class<BaseProcessor>]
        # @param walker [Walker]
        # @return [BaseProcessor]
        def processor processor_class, walker
          # @type [Hash{Class<BaseProcessor> => BaseProcessor}]
          processors = (@processors ||= {})
          processors[processor_class] ||= processor_class.new(walker)
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
        # @param node [::Parser::AST::Node]
        # @return [Array<Handler>]
        def handlers_for event, node
          type = node.type
          # @sg-ignore The method name of a send node is a Symbol child
          # @type [Symbol, nil]
          method_name = node.children[1] if SEND_TYPES.include?(type)
          table = (dispatch_tables[event] ||= {})[type] ||= {}
          table[method_name] ||= handlers_of(event).select { |handler| handler.applies_to?(type, method_name) }
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

        # @return [Hash{Symbol => Hash{Symbol => Hash{Symbol, nil => Array<Handler>}}}]
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

        enter = Walker.handlers_for(:enter, node)
        leave = Walker.handlers_for(:leave, node)
        return walk_children(node, region) if enter.empty? && leave.empty?

        frame = Frame.new(node, region)
        @frames.push frame
        dispatch enter, frame
        process_children unless frame.children_processed
        dispatch leave, frame, halts: false
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
        walk_children(frame.node, subregion)
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

      # @param node [::Parser::AST::Node]
      # @param region [Region]
      # @return [Array]
      def walk_children node, region
        node.children.each { |child| walk(child, region) if child.is_a?(::Parser::AST::Node) }
      end

      # @param handlers [Array<Handler>]
      # @param frame [Frame]
      # @param halts [Boolean] whether Walker#halt stops the remaining handlers
      # @return [void]
      def dispatch handlers, frame, halts: true
        handlers.each do |handler|
          break if halts && frame.halted

          captures = handler.match(frame.node)
          next unless captures

          frame.processor(handler.processor_class, self).handle(handler.callback, captures)
        end
      end
    end
  end
end
