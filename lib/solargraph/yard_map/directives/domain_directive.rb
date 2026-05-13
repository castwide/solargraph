# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module DomainDirective
        module_function

        # @param source [Solargraph::Source]
        # @param _pins [Array<Solargraph::Pin::Base>]
        # @param source_position [Position]
        # @param _comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Solargraph::Pin::Method>]
        def process_directive source, _pins, source_position, _comment_position, directive
          namespace = closure_at(pins, source_position) || Pin::ROOT_PIN
          namespace.domains.concat directive.tag.types unless directive.tag.types.nil?
          []
        end

        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
