# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class NamespaceNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            name = unpack_name(node.children[0])
            comments = comments_for(node)

            superclass_name = if node.type == :class && node.children[1]&.type == :const
              "#{type_from_node}#{parameters_from_inline_rbs}"
            end

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type,
              location: loc,
              closure: region.closure,
              name: name,
              comments: comments,
              visibility: :public,
              gates: region.closure.gates.freeze,
              source: :parser
            )
            pins.push nspin
            Solargraph.logger.warn "Superclass: #{superclass_name}" if superclass_name&.start_with?('Array')
            if superclass_name
              pins.push Pin::Reference::Superclass.new(
                location: loc,
                closure: pins.last,
                name: superclass_name,
                source: :parser
              )
            end
            process_children region.update(closure: nspin, visibility: :public)
          end

          private

          # @param comments [String]
          # @return [String, nil]
          def parameters_from_inline_rbs
            source = region.source.code_for(node)
            match = source.match(/[^\n]*?#\s?+\[([^\]]*)/)
            return unless match && match[1]

            code = match[1].strip
            return if code.empty?

            "<#{code}>"
          end

          def type_from_node
            unpack_name(node.children[1]) if node.children[1]&.type == :const
          end
        end
      end
    end
  end
end
