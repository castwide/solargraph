# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of YARD macros.
      #
      class Inference < Base
        def expand
          return infer_from_block_receiver(pin, receiver) if receiver.is_a?(Pin::Block)

          case pin
          when Pin::BaseVariable, Pin::Constant
            return_types_from_node(pin.assignment)
          else
            return_types_from_node(next_node)
          end
        end

        private

        def source_map
          api_map.source_map(pin.filename)
        end

        def position
          receiver.location.range.start
        end

        def infer_from_block_receiver pin, receiver
          # @todo For now, we assume that an undefined typeset from call chain
          #   inference requires a type to be inferred from the block chain. We
          #   might need to make it more accurate, e.g., the call chain should
          #   be calling the native `yield` method or `call` on a block parameter.
          if next_chain
            chain_inferred = Dictionary.new(api_map, pin.filename, Range.from_node(next_chain.node).start, chain: next_chain).infer
            return chain_inferred unless chain_inferred.to_s == 'undefined' || chain_inferred.to_s.empty?
          end

          call_chain = Solargraph::Parser::ParserGem::NodeChainer.chain(receiver.node)
          Dictionary.new(api_map, pin.filename, receiver.location.range.start, chain: call_chain.links.last.block).infer
        end

        # @param pin [Pin::Base]
        # @return [Source::Chain, nil]
        def next_chain
          @next_chain ||= if pin.location
            Parser::ParserGem::NodeChainer.chain(source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column))
          end
        end

        def next_node
          @next_node ||= begin
            if pin.is_a?(Pin::Method)
              method_body_node
            else
              return unless pin.location
              source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
            end
          end
        end

        # @param pin [Pin::Base]
        # @return [Parser::AST::Node, nil]
        def method_body_node
          @method_body_node ||= begin
            # node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
            node = pin.node
            return unless node
            return node.children[1].children.last if node.type == :DEFN
            return node.children[2].children.last if node.type == :DEFS
            return node.children[2] if %i[def DEFS].include?(node.type)
            node.children[3] if node.type == :defs
          end
        end

        # @param parent_node [Parser::AST::Node]
        # @return [Typeset]
        def return_types_from_node parent_node
          types = []
          Parser::ParserGem::NodeMethods.value_position_nodes_only(parent_node).each do |node|
            # Nil nodes may not have a location
            if node.nil? || node.type == :NIL || node.type == :nil
              types.push ComplexType::NIL.to_typedef_typeset
            else
              rng = Range.from_node(node)
              next if rng.nil?
              pos = rng.ending
              chain = Parser.chain(node, nil, nil)
              result = Dictionary.new(api_map, source_map, pos, chain: chain).infer
              types.push result
            end
          end
          return ComplexType::UNDEFINED.to_typedef_typeset if types.empty?
          Typeset.new(types)
        rescue FileNotFoundError
          # @todo Necessary for pins from source maps that are not part of the workspace
          [ComplexType::UNDEFINED]
        end
      end
    end
  end
end
