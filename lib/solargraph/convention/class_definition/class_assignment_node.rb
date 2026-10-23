# frozen_string_literal: true

module Solargraph
  module Convention
    module ClassDefinition
      # A node wrapper for a class definition via const assignment.
      # @example
      #   MyError = Class.new(StandardError) do
      #     def retry_after; 5; end
      #   end
      class ClassAssignmentNode
        class << self
          # @example
          #   s(:casgn, nil, :Foo,
          #     s(:block,
          #       s(:send,
          #         s(:const, nil, :Class), :new,
          #         s(:const, nil, :StandardError)),
          #       s(:args),
          #       s(:def, :retry_after, s(:args), s(:int, 5))))
          #
          # @param node [Parser::AST::Node]
          # @return [Boolean]
          def match? node
            return false unless node&.type == :casgn

            class_new_node?(new_node(node))
          end

          # The `Class.new(...)` send node, whether or not a block is attached.
          #
          # @param node [Parser::AST::Node]
          # @return [Parser::AST::Node, nil]
          def new_node node
            # s(:casgn, scope, name, value) - value is absent when the target is in an mlhs
            node => [:casgn, _, _, *rest]
            return nil unless rest in [::Parser::AST::Node => value, *]

            (value in [:block, ::Parser::AST::Node => call, *]) ? call : value
          end

          private

          # @param send_node [Parser::AST::Node, nil]
          # @return [Boolean]
          # @sg-ignore https://github.com/castwide/solargraph/pull/1416
          def class_new_node? send_node
            # s(:send, s(:const, scope, :Class), :new, *args)
            send_node in [:send, ::Parser::AST::Node[:const, _, :Class], :new, *]
          end
        end

        # @param node [Parser::AST::Node]
        def initialize node
          @node = node
        end

        # @return [String]
        def class_name
          # s(:casgn, scope, name, value) - scope is nil for a bare name
          node => [:casgn, ::Parser::AST::Node | nil => scope, Symbol => name, *]
          # @sg-ignore https://github.com/castwide/solargraph/pull/1416
          return name.to_s if scope.nil?

          "#{Parser::NodeMethods.unpack_name(scope)}::#{name}"
        end

        # The superclass, when it is written as a constant. `Class.new(expr)`
        # with a non-constant argument yields nil (superclass stays Object).
        #
        # @return [String, nil]
        def superclass_name
          send_node = self.class.new_node(node)
          return nil if send_node.nil?

          # s(:send, receiver, :new, superclass, *) - superclass is absent for a bare Class.new
          return nil unless send_node in [:send, _, _, ::Parser::AST::Node[:const, *] => superclass, *]

          Parser::NodeMethods.unpack_name(superclass)
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node
      end
    end
  end
end
