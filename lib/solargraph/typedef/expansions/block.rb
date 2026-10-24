# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Expansion of code with block receivers.
      #
      class Block < Base
        def expand
          node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
          call_chain = Parser.chain(node)
          chain_inferred = Dictionary.new(api_map, pin.filename, Range.from_node(call_chain.node).start, chain: call_chain).infer
          return chain_inferred unless chain_inferred.to_s == 'undefined' || chain_inferred.to_s.empty?

          call_chain = Solargraph::Parser::ParserGem::NodeChainer.chain(receiver.node)
          return Dictionary.new(api_map, pin.filename, receiver.location.range.start, chain: call_chain.links.last.block).infer
        end

        private

        def source_map
          api_map.source_map(pin.filename)
        end
      end
    end
  end
end
