# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Expansion of source code.
      #
      class Inference < Base
        def expand
          if receiver.is_a?(Pin::Block)
            from_block = Block.expand(api_map, pin, receiver) if receiver.is_a?(Pin::Block)
            # @todo Continuing on undefined seems to work in most cases, but we
            #   should use a more precise condition to determine whether block
            #   expansion is necessary in the first place.
            return from_block if from_block.defined?
          end

          case pin
          when Pin::BaseVariable, Pin::Constant
            return_typeset_from_node(pin.assignment)
          else
            return_typeset_from_node(next_node)
          end
        end

        private

        def source_map
          api_map.source_map(pin.filename)
        end

        def position
          receiver.location.range.start
        end

        def next_node
          @next_node ||= if pin.is_a?(Pin::Method)
                           method_body_node
                         else
                           return unless pin.location
                           source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
                         end
        end

        # @param pin [Pin::Base]
        # @return [Parser::AST::Node, nil]
        def method_body_node
          @method_body_node ||= case pin.node.type
                                when :def
                                  pin.node.children[2]
                                when :defs
                                  pin.node.children[3]
                                end
        end

        # @param parent_node [Parser::AST::Node]
        # @return [Typeset]
        def return_typeset_from_node parent_node
          types = []
          Parser::ParserGem::NodeMethods.value_position_nodes_only(parent_node).each do |node|
            # Nil nodes may not have a location
            if node.nil? || node.type == :NIL || node.type == :nil
              types.push ComplexType::NIL.to_typedef_typeset
            else
              chain = Parser.chain(node, nil, nil)
              result = Dictionary.new(api_map, source_map, chain).infer
              types.push result
            end
          end
          return ComplexType::UNDEFINED.to_typedef_typeset if types.empty?
          Typeset.new(types)
        rescue FileNotFoundError
          # @todo Necessary for pins from source maps that are not part of the workspace
          ComplexType::UNDEFINED.to_typedef_typeset
        end
      end
    end
  end
end
