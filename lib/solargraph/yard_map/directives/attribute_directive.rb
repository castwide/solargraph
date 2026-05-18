# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      module AttributeDirective
        module_function

        # @param source [Solargraph::Source]
        # @param pins [Array<Solargraph::Pin::Base>]
        # @param source_position [Position]
        # @param comment_position [Position]
        # @param directive [YARD::Tags::Directive]
        # @return [Array<Solargraph::Pin::Method>]
        def process_directive source, pins, source_position, comment_position, directive
          new_pins = []
          location = Location.new(source.filename, Range.new(comment_position, comment_position))
          docstring = Solargraph::Source.parse_docstring(directive.tag.text.to_s).to_docstring
          return [] if directive.tag.name.nil?
          namespace = closure_at(pins, source_position)
          t = directive.tag.types.nil? || directive.tag.types.empty? ? nil : directive.tag.types.join
          if t.nil? || t.include?('r')
            new_pins.push Solargraph::Pin::Method.new(
              location: location,
              closure: namespace,
              name: directive.tag.name,
              comments: docstring.all.to_s,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public,
              explicit: false,
              attribute: true,
              source: :yard_map
            )
          end
          if t.nil? || t.include?('w')
            write_pin = Solargraph::Pin::Method.new(
              location: location,
              closure: namespace,
              name: "#{directive.tag.name}=",
              comments: docstring.all.to_s,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public,
              attribute: true,
              source: :yard_map
            )
            new_pins.push(write_pin)
            write_pin.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: write_pin, source: :yard_map)
            if write_pin.return_type&.defined?
              write_pin.docstring.add_tag YARD::Tags::Tag.new(:param, '', write_pin.return_type.to_s.split(', '), 'value')
            end
          end

          new_pins.compact
        end

        # @param [Array<Pin::Base>] pins
        # @param [Position] position
        # @return [Pin::Closure]
        def closure_at pins, position
          pins.select { |pin| pin.is_a?(Pin::Closure) and pin.location&.range&.contain?(position) }.last
        end
      end
    end
  end
end
