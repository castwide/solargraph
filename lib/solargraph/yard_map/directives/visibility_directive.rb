# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module VisibilityDirective
        module_function

        VALID_VISIBILITIES = %i[public protected private].freeze

        # @param source [Solargraph::Source]
        # @param pins [Array<Solargraph::Pin::Base>]
        # @param source_position [Position]
        # @param comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Solargraph::Pin::Method>]
        def process_directive source, pins, source_position, comment_position, directive
          kind = directive.tag.text&.to_sym
          return unless VALID_VISIBILITIES.include?(kind)

          name = directive.tag.name
          closure = closure_at(pins, source_position) || @pins.first
          if closure.location.range.start.line < comment_position.line
            closure = closure_at(pins, comment_position)
          end
          if closure.is_a?(Pin::Method) && no_empty_lines?(source.code, comment_position.line, source_position.line)
            # @todo Smelly instance variable access
            closure.instance_variable_set(:@visibility, kind)
          else
            matches = pins.select do |pin|
              if pin.is_a?(Pin::Method) &&
                 pin.name == name &&
                 pin.namespace == namespace &&
                 pin.context.scope == namespace.is_a?(Pin::Singleton)
                :class
              else
                :instance
              end
            end

            matches.each do |pin|
              # @todo Smelly instance variable access
              pin.instance_variable_set(:@visibility, kind)
            end
          end

          []
        end

        def no_empty_lines? code, line1, line2
          code.lines[line1..line2].none? { |line| line.strip.empty? }
        end

        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position) }.last
        end
      end
    end
  end
end
