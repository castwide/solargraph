# frozen_string_literal: true

module Solargraph
  module Pin
    # A fact that 'h[k]' is present, i.e. that a Hash lookup can't return
    # nil for want of a key, within a range of a closure: e.g. after
    # 'return unless h.key?(k)' or 'h[k] ||= v'.
    #
    # The receiver and key are expressions, each a list of steps such as
    # [:lvar, :h], [:ivar, :@h], [:cvar, :@@h], [:self_call, :table]
    # (an attr_reader on self, called as 'table' or 'self.table'), or
    # [:call, :filename] (an attr_reader on the previous step). A literal
    # key is the single step [:literal, :sym, :a].
    class KeyLookup < Base
      # @return [::Array<::Array>]
      attr_reader :receiver

      # @return [::Array<::Array>]
      attr_reader :key

      # @return [Range]
      attr_reader :presence

      # @return [::Parser::AST::Node, nil] the 'v' in 'h[k] ||= v', which
      #   must not be nil for the fact to hold
      attr_reader :value

      # @param receiver [::Array<::Array>]
      # @param key [::Array<::Array>]
      # @param presence [Range]
      # @param value [::Parser::AST::Node, nil]
      # @param splat [Hash{Symbol => Object}]
      def initialize receiver:, key:, presence:, value: nil, **splat
        super(**splat)
        @receiver = receiver
        @key = key
        @presence = presence
        @value = value
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      # @return [Boolean]
      def visible_at? other_closure, other_loc
        return false unless location&.filename == other_loc.filename && presence.include?(other_loc.range.start)

        within?(other_closure)
      end

      # @param node [::Parser::AST::Node, nil]
      # @return [::Array<::Array>, nil] the steps `node` reads, or nil
      #   unless it is made of variables and argument-less calls
      def self.steps_from_node node
        return unless node.is_a?(::Parser::AST::Node)
        return [[node.type, node.children[0]]] if %i[lvar ivar cvar].include?(node.type)
        return unless node.type == :send && node.children.length == 2

        receiver, method_name = node.children
        return [[:self_call, method_name]] if receiver.nil? || receiver.type == :self

        base = steps_from_node(receiver)
        base && (base + [[:call, method_name]])
      end

      # @param node [::Parser::AST::Node, nil]
      # @return [::Array<::Array>, nil]
      def self.key_steps_from_node node
        return unless node.is_a?(::Parser::AST::Node)
        return [[:literal, node.type, node.children[0]]] if %i[str sym int].include?(node.type)

        steps_from_node(node)
      end

      private

      # @param viewing [Pin::Closure, nil]
      # @return [Boolean] true if `viewing` is this fact's closure or
      #   nested in it
      def within? viewing
        return false if viewing.nil?

        viewing == closure || within?(viewing.closure)
      end
    end
  end
end
