# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module ParseDirective
        module_function

        # @param source [Solargraph::Source]
        # @param pins [Array<Solargraph::Pin::Base>]
        # @param source_position [Position]
        # @param comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Solargraph::Pin::Method>]
        def process_directive source, pins, source_position, comment_position, directive
          ns = closure_at(pins, source_position)
          pins_copy = pins.dup
          src = Solargraph::Source.load_string(directive.tag.text, source.filename)
          region = Parser::Region.new(source: src, closure: ns)
          # @todo These pins may need to be marked not explicit
          old_pins_index = pins.length
          loff = if source.code.lines[comment_position.line].strip.end_with?('@!parse')
                   comment_position.line + 1
                 else
                   comment_position.line
                 end
          Parser.process_node(src.node, region, pins_copy)
          new_pins = pins_copy[old_pins_index..]
          new_pins.each do |p|
            # @todo Smelly instance variable access
            p.location.range.start.instance_variable_set(:@line, p.location.range.start.line + loff)
            p.location.range.ending.instance_variable_set(:@line, p.location.range.ending.line + loff)
          end

          new_pins
        rescue Parser::SyntaxError
          # @todo Handle parser errors in !parse directives
          []
        end

        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
