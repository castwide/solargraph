# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module OverrideDirective
        module_function

        # @param source [Solargraph::Source]
        # @param _pins [Array<Solargraph::Pin::Base>]
        # @param _source_position [Position]
        # @param comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Pin::Base>]
        def process_directive source, _pins, _source_position, comment_position, directive
          docstring = Solargraph::Source.parse_docstring(directive.tag.text.to_s).to_docstring
          location = Location.new(source.filename, Range.new(comment_position, comment_position))
          [Pin::Reference::Override.new(location, directive.tag.name.to_s, docstring.tags, source: :yard_map)]
        end

        # @param [Array<Pin::Base>] pins
        # @param [Position] position
        # @return [Pin::Closure]
        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
