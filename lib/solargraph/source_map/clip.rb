# frozen_string_literal: true

module Solargraph
  class SourceMap
    # A static analysis tool for obtaining definitions, completions,
    # signatures, and type inferences from a cursor.
    #
    class Clip
      # @param api_map [ApiMap]
      # @param cursor [Source::Cursor]
      def initialize api_map, cursor
        @api_map = api_map
        @cursor = cursor
      end

      # @return [Array<Pin::Base>]
      def define
        return [] if cursor.comment? || cursor.chain.literal?
        result = cursor.chain.define(api_map, block, locals)
        result.concat((source_map.pins + source_map.locals).select{ |p| p.name == cursor.word && p.location.range.contain?(cursor.position) }) if result.empty?
        result
      end

      # @return [Completion]
      def complete
        return package_completions([]) if !source_map.source.parsed? || cursor.string?
        return package_completions(api_map.get_symbols) if cursor.chain.literal? && cursor.chain.links.last.word == '<Symbol>'
        return Completion.new([], cursor.range) if cursor.chain.literal? || cursor.comment?
        result = []
        result.concat complete_keyword_parameters
        if cursor.chain.constant? || cursor.start_of_constant?
          if cursor.chain.undefined?
            type = cursor.chain.base.infer(api_map, context_pin, locals)
          else
            full = cursor.chain.links.first.word
            if full.include?('::') && cursor.chain.links.length == 1
              type = ComplexType.try_parse(full.split('::')[0..-2].join('::'))
            elsif cursor.chain.links.length > 1
              type = ComplexType.try_parse(full)
            else
              type = ComplexType::UNDEFINED
            end
          end
          result.concat api_map.get_constants(type.undefined? ? '' : type.namespace, cursor.start_of_constant? ? '' : context_pin.full_context.namespace, *gates)
        else
          type = cursor.chain.base.infer(api_map, block, locals)
          result.concat api_map.get_complex_type_methods(type, block.binder.namespace, cursor.chain.links.length == 1)
          if cursor.chain.links.length == 1
            if cursor.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(context_pin.full_context.namespace))
            elsif cursor.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(block.binder.namespace, block.binder.scope))
            elsif cursor.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            end
            result.concat locals
            result.concat api_map.get_constants(context_pin.context.namespace, *gates)
            result.concat api_map.get_methods(block.binder.namespace, scope: block.binder.scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            result.concat ApiMap.keywords
            result.concat yielded_self_pins
          end
        end
        package_completions(result)
      end

      # @return [Array<Pin::Base>]
      def signify
        return [] unless cursor.argument?
        chain = Source::NodeChainer.chain(cursor.recipient_node, cursor.filename)
        chain.define(api_map, context_pin, locals).select { |pin| pin.is_a?(Pin::Method) }
      end

      # @return [ComplexType]
      def infer
        result = cursor.chain.infer(api_map, block, locals)
        return result unless result.tag == 'self'
        ComplexType.try_parse(cursor.chain.base.infer(api_map, block, locals).namespace)
      end

      # Get an array of all the locals that are visible from the cursors's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        loc_pos = context_pin.location.range.contain?(cursor.position) ? cursor.position : context_pin.location.range.ending
        adj_pos = Position.new(loc_pos.line, (loc_pos.column.zero? ? 0 : loc_pos.column - 1))
        @locals ||= source_map.locals.select { |pin|
          pin.visible_from?(block, adj_pos)
        }.reverse
      end

      def gates
        block.gates
      end

      def in_block?
        return @in_block unless @in_block.nil?
        @in_block = begin
          tree = cursor.source.tree_at(cursor.position.line, cursor.position.column)
          tree[1].is_a?(Parser::AST::Node) && tree[1].type == :block
        end
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

      # The context at the current position.
      #
      # @return [Pin::Base]
      def context_pin
        @context_pin ||= source_map.locate_named_path_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # @return [Array<Pin::Base>]
      def yielded_self_pins
        return [] unless block.is_a?(Pin::Block) && block.receiver
        chain = Solargraph::Source::NodeChainer.chain(block.receiver, source_map.source.filename)
        receiver_pin = chain.define(api_map, context_pin, locals).first
        return [] if receiver_pin.nil?
        result = []
        ys = receiver_pin.docstring.tag(:yieldpublic)
        unless ys.nil? || ys.types.empty?
          ysct = ComplexType.try_parse(*ys.types).qualify(api_map, receiver_pin.context.namespace)
          result.concat api_map.get_complex_type_methods(ysct, '', false)
        end
        result
      end

      # @return [Array<Pin::KeywordParam]
      def complete_keyword_parameters
        return [] unless cursor.argument? && cursor.chain.links.one? && cursor.word =~ /^[a-z0-9_]*:?$/
        pins = signify
        result = []
        done = []
        pins.each do |pin|
          pin.parameter_names.each do |name|
            next if done.include?(name)
            done.push name
            if pin.parameters.any? { |par| par.start_with?("#{name}:") }
              result.push Pin::KeywordParam.new(pin.location, "#{name}:")
            end
          end
          if !pin.parameters.empty? && pin.parameters.last.start_with?('**') || pin.parameters.last =~ /= *?\{\}$/
            pin.docstring.tags(:param).each do |tag|
              next if done.include?(tag.name)
              done.push tag.name
              result.push Pin::KeywordParam.new(pin.location, "#{tag.name}:")
            end
          end
        end
        result
      end

      # @param result [Array<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = cursor.start_of_word.to_s.downcase
        filtered = result.uniq(&:name).select { |s|
          s.name.downcase.start_with?(frag_start) &&
            (!s.is_a?(Pin::BaseMethod) || s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))
        }
        Completion.new(filtered, cursor.range)
      end
    end
  end
end
