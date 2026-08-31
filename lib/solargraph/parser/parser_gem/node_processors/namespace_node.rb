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

          # Type arguments for a generic superclass in inline RBS syntax, e.g.,
          # `class Foo < Array #[String]`. Only recognized where RBS defines
          # it: directly after the superclass, on the same line, with no space
          # between `#` and `[`. Anything else is an ordinary comment.
          #
          # @return [String, nil]
          def parameters_from_inline_rbs
            superclass = node.children[1]
            return unless superclass

            source = region.source.code
            pos = get_node_end_position(superclass)
            offset = Position.line_char_to_offset(source, pos.line, pos.character)
            eol = source.index("\n", offset) || source.length
            match = source[offset...eol].to_s.match(/\A\s*#\[([^\]]*)\]/)
            return unless match

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
