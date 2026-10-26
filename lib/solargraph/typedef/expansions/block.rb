# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Expansion of code with block receivers.
      #
      class Block < Base
        def expand
          case pin
          when Pin::Parameter
            # Check for yieldparam tags
            return yieldparam_type if yieldparam_type
            ComplexType::UNDEFINED.to_typedef_typeset
          else
            node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
            call_chain = Parser.chain(node)
            chain_inferred = Dictionary.new(api_map, pin.filename, Range.from_node(call_chain.node).start, chain: call_chain).infer
            return chain_inferred unless chain_inferred.to_s == 'undefined' || chain_inferred.to_s.empty?

            call_chain = Solargraph::Parser::ParserGem::NodeChainer.chain(receiver.node)
            Dictionary.new(api_map, pin.filename, receiver.location.range.start, chain: call_chain.links.last.block).infer
          end
        end

        private

        def source_map
          api_map.source_map(pin.filename)
        end

        def caller_pins
          @caller_pin ||= Dictionary.new(api_map, pin.filename, pin.location.range.start, chain: Parser.chain(receiver.receiver)).define
        end

        def yieldparam_tags
          @yieldparam_tags ||= caller_pins.find { |pin| pin.docstring.tags(:yieldparam).any? }
                                          &.docstring&.tags(:yieldparam) || []
        end

        def yieldparam_matching_tag
          @yieldparam_match ||= yieldparam_tags[receiver.parameters.find_index { |param| param.name == pin.name }]
        end

        def yieldparam_type
          @yieldparam_type ||= ComplexType.parse(yieldparam_matching_tag.type).to_typedef_typeset if yieldparam_matching_tag
        end
      end
    end
  end
end
