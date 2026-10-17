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
            value = node.children[2]
            return nil if value.nil?
            return value unless value.type == :block

            value.children[0]
          end

          private

          # @param send_node [Parser::AST::Node, nil]
          # @return [Boolean]
          def class_new_node? send_node
            return false if send_node.nil?
            return false unless send_node.type == :send
            return false unless send_node.children[1] == :new

            receiver = send_node.children[0]
            return false if receiver.nil?
            return false unless receiver.type == :const

            receiver.children[1] == :Class
          end
        end

        # @param node [Parser::AST::Node]
        def initialize node
          @node = node
        end

        # @return [String]
        def class_name
          namespace = node.children[0]
          return node.children[1].to_s if namespace.nil?

          "#{Parser::NodeMethods.unpack_name(namespace)}::#{node.children[1]}"
        end

        # The superclass, when it is written as a constant. `Class.new(expr)`
        # with a non-constant argument yields nil (superclass stays Object).
        #
        # @return [String, nil]
        def superclass_name
          send_node = self.class.new_node(node)
          return nil if send_node.nil?

          arg = send_node.children[2]
          return nil if arg.nil?
          return nil unless arg.type == :const

          Parser::NodeMethods.unpack_name(arg)
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node
      end
    end
  end
end
