# frozen_string_literal: true

module Solargraph
  module Typedef
    class VariableFlow
      # @todo Candidate for deprecation
      include Solargraph::Parser::NodeMethods

      attr_reader :var_name, :position, :typeset, :tree

      # @param var_name [String]
      # @param position [Position]
      # @param typeset [Typeset]
      # @param tree [Array<Parser::AST::Node>]
      def initialize var_name, position, typeset, tree
        @var_name = var_name
        @position = position
        @typeset = typeset
        @tree = tree
      end

      # Narrow the type of a variable reference using the control flow of
      # the enclosing conditions, e.g., within the +then+ branch of
      # +if a.is_a?(String)+, a reference to +a+ is narrowed to +String+.
      #
      def reduce
        return typeset if typeset.undefined?

        tree.reduce(typeset) do |set, node|
          narrow_at(set, node, position)
        end
      end

      private
      
      # Narrows a typeset by the condition of a single control flow node if
      # the reference is in a branch where the condition is known to be
      # truthy or falsy.
      #
      # @param typeset [Typedef::Typeset]
      # @param node [Parser::AST::Node]
      # @param position [Position]
      # @return [Typedef::Typeset]
      def narrow_at typeset, node, position
        condition, polarity = condition_and_polarity(node, position)
        return typeset if condition.nil? || polarity.nil?

        check = narrowing_check(condition)
        return typeset unless check

        name, negated = check
        matches = ->(type) { type.to_s.delete_prefix('::') == name.delete_prefix('::') }
        satisfied = negated ? !polarity : polarity
        kept = satisfied ? typeset.types.select(&matches) : typeset.types.reject(&matches)
        result = Typeset.new(kept)
        result.types.empty? ? typeset : result
      end

      # The condition of a control flow node and whether it is known to be
      # truthy (+true+) or falsy (+false+) at the specified position.
      #
      # @param node [Parser::AST::Node]
      # @param position [Position]
      # @return [Array(Parser::AST::Node, Boolean), nil]
      def condition_and_polarity node, position
        case node.type
        when :if
          condition, if_branch, else_branch = *node
          if if_branch && Range.from_node(if_branch)&.contain?(position)
            [condition, true]
          elsif else_branch && Range.from_node(else_branch)&.contain?(position)
            [condition, false]
          end
        when :while, :until
          condition, body = *node
          [condition, node.type == :while] if body&.loc && Range.from_node(body).contain?(position)
        when :and
          left, right = *node
          [left, true] if right&.loc && Range.from_node(right).contain?(position)
        when :or
          left, right = *node
          [left, false] if right&.loc && Range.from_node(right).contain?(position)
        end
      end

      # The type name tested by an +is_a?+ (or +kind_of?+) check on the
      # link's variable, e.g., +String+ for +a.is_a?(String)+. The second
      # element is true for the negated form +!a.is_a?(String)+.
      #
      # @param condition [Parser::AST::Node]
      # @return [Array(String, Boolean), nil]
      def narrowing_check condition
        node = condition
        negated = false
        while node
          case node.type
          when :begin
            node = node.children.first
          when :send
            if node.children[1] == :! && node.children[0]&.type == :send && node.children[0].children[1] == :is_a?
              negated = !negated
              node = node.children[0]
              next
            end
            break
          else
            break
          end
        end
        return unless node&.type == :send && %i[is_a? kind_of?].include?(node.children[1])

        return unless receiver_name?(node.children[0])

        argument = node.children[2]
        return unless argument&.type == :const

        [unpack_name(argument), negated]
      end

      # True if the node is a bare reference to the link's variable, e.g.,
      # +s(:lvar, :a)+ or a receiverless +s(:send, nil, :a)+.
      #
      # @param node [Parser::AST::Node, nil]
      # @return [Boolean]
      def receiver_name? node
        return false unless node

        case node.type
        when :lvar, :ivasgn, :ivar, :gvar, :cvar
          node.children[0].to_s == var_name
        when :send
          node.children[0].nil? && node.children[1].to_s == var_name
        else
          false
        end
      end
    end
  end
end
