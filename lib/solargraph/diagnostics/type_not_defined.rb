module Solargraph
  module Diagnostics
    # RequireNotFound reports required paths that could not be resolved to
    # either a file in the workspace or a gem.
    #
    class TypeNotDefined < Base
      def diagnose source, api_map
        result = []
        source.pins.select{|p| p.kind == Pin::METHOD or p.kind == Pin::ATTRIBUTE}.each do |pin|
          unless defined_return_type?(pin, api_map)
            result.push(
              range: extract_first_line(pin, source),
              severity: Diagnostics::Severities::WARNING,
              source: 'Solargraph',
              message: "Method `#{pin.name}` has undefined return type."
            )
          end
          pin.parameters.each do |par|
            next if defined_param_type?(pin, par, api_map)
            result.push(
              range: extract_first_line(pin, source),
              severity: Diagnostics::Severities::WARNING,
              source: 'Solargraph',
              message: "Method `#{pin.name}` has undefined param `#{par}`."
            )
          end
        end
        result
      end

      private

      def extract_first_line pin, source
        {
          start: {
            line: pin.location.range.start.line,
            character: pin.location.range.start.character
          },
          end: {
            line: pin.location.range.start.line,
            character: last_character(pin.location.range.start, source)
          }
        }
      end

      def defined_return_type? pin, api_map
        return true unless pin.return_type.nil?
        matches = api_map.get_methods(pin.namespace, scope: pin.scope, visibility: [:public, :private, :protected]).select{|p| p.name == pin.name}
        matches.any?{|m| !m.return_type.nil?}
      end

      def defined_param_type? pin, param, api_map
        return true if pin.typed_parameters.any?{|p| p.name == param}
        matches = api_map.get_methods(pin.namespace, scope: pin.scope, visibility: [:public, :private, :protected]).select{|p| p.name == pin.name}
        matches.each do |m|
          return true if m.typed_parameters.any?{|p| p.name == param}
        end
        false
      end

      # @param position [Solargraph::Source::Position]
      # @param source [Solargraph::Source]
      # @return [Integer]
      def last_character position, source
        cursor = Source::Position.to_offset(source.code, position)
        source.code.index(/[\r\n]/, cursor) || source.code.length
      end
    end
  end
end
