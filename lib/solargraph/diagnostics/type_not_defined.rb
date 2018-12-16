module Solargraph
  module Diagnostics
    # TypeNotDefined reports methods with undefined return types, untagged
    # parameters, and invalid param tags.
    #
    class TypeNotDefined < Base
      def diagnose source, api_map
        result = []
        api_map.document_symbols(source.filename).each do |pin|
          next unless pin.kind == Pin::METHOD or pin.kind == Pin::ATTRIBUTE
          result.concat check_return_type(pin, api_map, source)
          result.concat check_param_types(pin, api_map, source)
          result.concat check_param_tags(pin, api_map, source)
        end
        result
      end

      private

      def check_return_type pin, api_map, source
        return [] if (pin.name == 'initialize' && pin.scope == :instance) || (pin.name == 'new' && pin.scope == :class)
        result = []
        unless defined_return_type?(pin, api_map)
          result.push(
            range: extract_first_line(pin, source),
            severity: Diagnostics::Severities::WARNING,
            source: 'Solargraph',
            message: "Method `#{pin.name}` has undefined return type."
          )
        end
        result
      end

      def check_param_types pin, api_map, source
        return [] if pin.name == 'new' and pin.scope == :class
        result = []
        pin.parameter_names.each do |par|
          next if defined_param_type?(pin, par, api_map)
          result.push(
            range: extract_first_line(pin, source),
            severity: Diagnostics::Severities::WARNING,
            source: 'Solargraph',
            message: "Method `#{pin.name}` has undefined param `#{par}`."
          )
        end
        result
      end

      def check_param_tags pin, api_map, source
        result = []
        pin.docstring.tags(:param).each do |par|
          next if pin.parameter_names.include?(par.name)
          result.push(
            range: extract_first_line(pin, source),
            severity: Diagnostics::Severities::WARNING,
            source: 'Solargraph',
            message: "Method `#{pin.name}` has mistagged param `#{par.name}`."
          )
        end
        result
      end

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
        return true unless pin.return_complex_type.undefined?
        matches = api_map.get_method_stack(pin.namespace, pin.name, scope: pin.scope)
        matches.shift
        matches.any?{|m| !m.return_complex_type.undefined?}
      end

      def defined_param_type? pin, param, api_map
        return true if param_in_docstring?(param, pin.docstring)
        matches = api_map.get_method_stack(pin.namespace, pin.name, scope: pin.scope)
        matches.shift
        matches.each do |m|
          next unless pin.parameter_names == m.parameter_names
          return true if param_in_docstring?(param, m.docstring)
        end
        false
      end

      def param_in_docstring? param, docstring
        tags = docstring.tags(:param)
        tags.any?{|t| t.name == param}
      end

      # @param position [Solargraph::Position]
      # @param source [Solargraph::Source]
      # @return [Integer]
      def last_character position, source
        cursor = Position.to_offset(source.code, position)
        source.code.index(/[\r\n]/, cursor) || source.code.length
      end
    end
  end
end
