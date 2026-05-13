# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module MethodDirective
        module_function

        # @param source [Solargraph::Source]
        # @param pins [Array<Solargraph::Pin::Base>]
        # @param source_position [Position]
        # @param comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Solargraph::Pin::Method>]
        def process_directive source, pins, source_position, comment_position, directive
          namespace = closure_at(pins, source_position) || pins.first
          namespace = closure_at(pins, comment_position) if namespace.location.range.start.line < comment_position.line
          begin
            src = Solargraph::Source.load_string("def #{directive.tag.name};end", source.filename)
            region = Parser::Region.new(source: src, closure: namespace)
            method_gen_pins = Parser.process_node(src.node, region).first.select { |pin| pin.is_a?(Pin::Method) }
            gen_pin = method_gen_pins.last
            return [] if gen_pin.nil?
            # Move the location to the end of the line so it gets recognized
            # as originating from a comment
            shifted = Solargraph::Position.new(comment_position.line,
                                               source.code.lines[comment_position.line].to_s.chomp.length)
            comments = Solargraph::Source.parse_docstring(directive.tag.text).to_docstring.all.to_s
            # @todo: Smelly instance variable access
            gen_pin.instance_variable_set(:@comments, comments)
            gen_pin.instance_variable_set(:@location,
                                          Solargraph::Location.new(source.filename, Range.new(shifted, shifted)))
            gen_pin.instance_variable_set(:@explicit, false)
            [gen_pin]
          rescue Parser::SyntaxError
            # @todo Handle error in directive
            []
          end
        end

        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
