# frozen_string_literal: true

module Solargraph
  module Pin
    # A refined type for an expression such as 'h[:k]' or '@a.b' within a
    # range of a closure, e.g. after 'return if h[:k].nil?'.
    #
    # Steps start at a variable root, [:lvar, :h], [:ivar, :@h], [:cvar, :@@h]
    # or [:self_call, :name], then [:call, :name] for an argument-less call
    # or [:call, :[], key] for an index whose key is [[:literal, :sym, :k]]
    # or a variable root.
    class ExpressionNarrowing < Base
      include ExpressionType

      # @return [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>]
      attr_reader :steps

      # @return [Range]
      attr_reader :presence

      # @return [ComplexType, nil] types the expression can't have here
      attr_reader :exclude_return_type

      # @return [::Array<ComplexType>] types the expression must match
      #   here; all of them apply
      attr_reader :intersection_return_types

      # @return [Proc, nil] given an ApiMap, returns whether the refinement
      #   holds, for conditions that need type inference to decide
      attr_reader :check

      # @param steps [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>]
      # @param presence [Range]
      # @param exclude_return_type [ComplexType, nil]
      # @param intersection_return_types [::Array<ComplexType>]
      # @param check [Proc, nil]
      # @param splat [Hash{Symbol => Object}]
      def initialize steps:, presence:, exclude_return_type: nil, intersection_return_types: [], check: nil,
                     **splat
        super(**splat)
        @steps = steps
        @presence = presence
        @exclude_return_type = exclude_return_type
        @intersection_return_types = intersection_return_types
        @check = check
      end

      # @return [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>]
      def expression
        steps
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      # @return [Boolean]
      def visible_at? other_closure, other_loc
        return false unless location&.filename == other_loc.filename && presence.include?(other_loc.range.start)

        within?(other_closure)
      end

      # @param api_map [ApiMap]
      # @param bindings [::Array<Pin::LocalVariable>] the local variables
      #   an occurrence of the same expression reads
      # @return [Boolean] true if this narrowing applies to that occurrence
      def proves? api_map, bindings
        bindings.all? { |variable| outer_binding?(variable) } && holds?(api_map)
      end

      # @param type [ComplexType, ComplexType::UniqueType]
      # @param api_map [ApiMap]
      # @return [ComplexType, ComplexType::UniqueType]
      def narrow type, api_map
        gates = closure&.gates || ['']
        narrowed = type.exclude(exclude_return_type&.qualify(api_map, *gates), api_map)
        intersection_return_types.each do |intersection|
          narrowed = narrowed.intersect_with(intersection.qualify(api_map, *gates), api_map)
        end
        narrowed
      end

      # @param node [::Parser::AST::Node, nil]
      # @return [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>, nil] the steps `node` reads, or nil
      #   unless it is a variable root followed by narrowable steps
      def self.steps_from_node node
        return if node.nil?

        root = root_step(node)
        return [root] if root
        return unless node.type == :send

        receiver = node.children[0]
        method_name = node.children[1]
        args = node.children.drop(2)
        return [[:self_call, method_name]] if args.empty? && (receiver.nil? || receiver.type == :self)

        base = steps_from_node(receiver)
        return unless base
        return base + [[:call, method_name]] if args.empty?

        return unless method_name == :[] && args.length == 1

        key = key_step(args.fetch(0))
        base + [[:call, :[], [key]]] if key
      end

      # @param node [::Parser::AST::Node]
      # @return [::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol), ::Array(:cvar, ::Symbol), nil]
      def self.root_step node
        [node.type, node.children[0]] if %i[lvar ivar cvar].include?(node.type)
      end

      # @param node [::Parser::AST::Node]
      # @return [::Array(:literal, :str, ::String), ::Array(:literal, :sym, ::Symbol),
      #   ::Array(:literal, :int, ::Integer), ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #   ::Array(:cvar, ::Symbol), nil]
      def self.key_step node
        return [:literal, node.type, node.children[0]] if %i[str sym int].include?(node.type)

        root_step(node)
      end
      private_class_method :root_step, :key_step

      private

      # @param api_map [ApiMap]
      # @return [Boolean]
      def holds? api_map
        check = self.check
        return true if check.nil?

        check.call(api_map) == true
      end

      # A local variable of the same name declared in a nested closure,
      # e.g. a block parameter, is a different variable from the one this
      # narrowing is about.
      #
      # @param variable [Pin::LocalVariable] a variable an occurrence reads
      # @return [Boolean] true if `variable` belongs to this narrowing's
      #   closure or one enclosing it
      def outer_binding? variable
        nested_in?(closure, variable.closure)
      end

      # @param scope [Pin::Closure, nil]
      # @param outer [Pin::Closure, nil]
      # @return [Boolean] true if `scope` is `outer` or nested in it
      def nested_in? scope, outer
        return false if scope.nil? || outer.nil?

        same_closure?(scope, outer) || nested_in?(scope.closure, outer)
      end

      # @param viewing [Pin::Closure, nil]
      # @return [Boolean] true if `viewing` is this narrowing's closure or
      #   nested in it
      def within? viewing
        return false if viewing.nil?

        same_closure?(viewing, closure) || within?(viewing.closure)
      end

      # module_function makes class and instance copies of one def; they
      # share its node, and so its body
      #
      # @param pin [Pin::Closure]
      # @param other [Pin::Closure, nil]
      # @return [Boolean]
      def same_closure? pin, other
        return true if pin == other

        pin.is_a?(Pin::Method) && other.is_a?(Pin::Method) && !pin.node.nil? && pin.node.equal?(other.node)
      end
    end
  end
end
