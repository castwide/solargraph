module Solargraph
  class SourceMap
    class Clip
      # @param api_map [ApiMap]
      # @param cursor [Source::Cursor]
      def initialize api_map, cursor
        # @todo Just some temporary stuff while I make sure this works
        raise "Not a cursor: #{cursor.class}" unless cursor.is_a?(Source::Cursor)
        @api_map = api_map
        @cursor = cursor
      end

      # @return [Array<Pin::Base>]
      def define
        return [] if cursor.chain.literal?
        result = cursor.chain.define(api_map, context_pin, locals)
        # HACK: Definitions of definitions should only be used if the cursor is at the top of the definition
        result.pop if cursor.chain.links.last.is_a?(Source::Chain::Definition) && result.last.location.range.start.line != cursor.position.line
        result
      end

      # @return [Completion]
      def complete
        return package_completions(api_map.get_symbols) if cursor.chain.literal? && cursor.chain.links.last.word == '<Symbol>'
        return Completion.new([], cursor.range) if cursor.chain.literal? || cursor.comment?
        result = []
        type = cursor.chain.base.infer(api_map, context_pin, locals)
        if cursor.chain.constant? || cursor.start_of_constant?
          result.concat api_map.get_constants(type.undefined? ? '' : type.namespace, cursor.start_of_constant? ? '' : context_pin.context.namespace)
        else
          result.concat api_map.get_complex_type_methods(type, context_pin.context.namespace, cursor.chain.links.length == 1)
          if cursor.chain.links.length == 1
            if cursor.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(context_pin.context.namespace))
            elsif cursor.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(context_pin.context.namespace, context_pin.context.scope))
            elsif cursor.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            end
            result.concat prefer_non_nil_variables(locals)
            result.concat api_map.get_constants('', context_pin.context.namespace)
            result.concat api_map.get_methods(context_pin.context.namespace, scope: context_pin.context.scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            result.concat ApiMap.keywords
          end
        end
        package_completions(result)
      end

      # @return [Array<Pin::Base>]
      def signify
        return [] unless cursor.argument?
        clip = Clip.new(api_map, cursor.recipient)
        clip.define.select{|pin| pin.kind == Pin::METHOD}
      end

      def infer
        cursor.chain.infer(api_map, context_pin, locals)
      end

      # The context at the current position.
      #
      # @return [Pin::Base]
      def context_pin
        @context ||= source_map.locate_named_path_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # Get an array of all the locals that are visible from the cursors's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= source_map.locals.select { |pin|
          pin.visible_from?(block, Position.new(cursor.position.line, (cursor.position.column.zero? ? 0 : cursor.position.column - 1)))
        }.reverse
      end

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [Source::Cursor]
      attr_reader :cursor

      # @return [SourceMap]
      def source_map
        @source_map ||= api_map.source_map(cursor.filename)
      end

      # @return [Solargraph::Pin::Base]
      def block
        @block ||= source_map.locate_block_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # @param cursor [cursor]
      # @param result [Array<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = cursor.start_of_word.to_s.downcase
        filtered = result.uniq(&:name).select{|s| s.name.downcase.start_with?(frag_start) and (s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))}
        Completion.new(filtered, cursor.range)
      end

      # Sort an array of pins to put nil or undefined variables last.
      #
      # @param pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def prefer_non_nil_variables pins
        result = []
        nil_pins = []
        pins.each do |pin|
          if pin.variable? and pin.nil_assignment?
            nil_pins.push pin
          else
            result.push pin
          end
        end
        result + nil_pins
      end
    end
  end
end
