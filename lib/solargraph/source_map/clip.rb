module Solargraph
  class SourceMap
    class Clip
      # @param api_map [ApiMap]
      # @param cursor [Source::Cursor]
      def initialize api_map, cursor
        # @todo Just some temporary stuff while I make sure this works
        raise "Not a cursor" unless cursor.is_a?(Source::Cursor)
        @api_map = api_map
        @cursor = cursor
      end

      # @return [Array<Pin::Base>]
      def define
        cursor.chain.define(api_map, context, locals)
      end

      # @return [Completion]
      def complete
        return Completion.new([], cursor.range) if cursor.chain.literal? or cursor.comment?
        result = []
        type = cursor.chain.base.infer(api_map, context, locals)
        if cursor.chain.constant? and !cursor.chain.links.length == 1
          result.concat api_map.get_constants(type.namespace, context.namespace)
        else
          result.concat api_map.get_complex_type_methods(type, context.namespace, cursor.chain.links.length == 1)
          if cursor.chain.links.length == 1
            if cursor.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(context.namespace))
            elsif cursor.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(context.namespace, context.scope))
            elsif cursor.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            elsif cursor.word.start_with?(':') and !cursor.word.start_with?('::')
              return package_completions(api_map.get_symbols)
            end
            result.concat api_map.get_constants('', context.namespace)
            result.concat prefer_non_nil_variables(locals)
            result.concat api_map.get_methods(context.namespace, scope: context.scope, visibility: [:public, :private, :protected])
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

      # The context at the current position.
      #
      # @return [Context]
      def context
        @context ||= source_map.locate_named_path_pin(cursor.node_position.line, cursor.node_position.character).context
      end

      # Get an array of all the locals that are visible from the cursors's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= source_map.locals.select { |pin|
          pin.visible_from?(block, cursor.node_position)
        }.reverse
      end

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [cursor]
      attr_reader :cursor

      def source_map
        api_map.source_map(cursor.filename)
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
        filtered = result.uniq(&:identifier).select{|s| s.name.downcase.start_with?(frag_start) and (s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))}.sort_by.with_index{ |x, idx| [x.name, idx] }
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
