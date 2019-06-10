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

      # @param pin [Pin::BaseMethod]
      # @param api_map [ApiMap]
      # @param source [Source]
      # @return [Array<Hash>]
      def check_return_type pin, api_map, source
        type = pin.typify(api_map)
        result = []
        if type.undefined?
          result.push(
            range: extract_first_line(pin, source),
            severity: Diagnostics::Severities::WARNING,
            source: 'Solargraph',
            message: "Method `#{pin.name}` has undefined return type."
          )
        end
        result
      end

      # @param pin [Pin::BaseMethod]
      # @param api_map [ApiMap]
      # @param source [Source]
      # @return [Array<Hash>]
      def check_param_types pin, api_map, source
        return [] if pin.name == 'new' and pin.scope == :class
        result = []
        smap = api_map.source_map(source.filename)
        locals = smap.locals_at(Location.new(source.filename, Solargraph::Range.from_to(pin.location.range.ending.line, pin.location.range.ending.column, pin.location.range.ending.line, pin.location.range.ending.column)))
        pin.parameter_names.each do |name|
          par = locals.select { |l| l.name == name }.first
          type = par.typify(api_map)
          if type.undefined?
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

      # @param pin [Pin::BaseMethod]
      # @param api_map [ApiMap]
      # @param source [Source]
      # @return [Array<Hash>]
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

      # @param pin [Pin::Base]
      # @param source [Source]
      # @return [Hash]
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
