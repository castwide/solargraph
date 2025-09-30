# frozen_string_literal: true

module Solargraph
  class SourceMap
    # A static analysis tool for obtaining definitions, Completions,
    # signatures, and type inferences from a Cursor.
    #
    class Clip
      # @param api_map [ApiMap]
      # @param cursor [Source::Cursor]
      def initialize api_map, cursor
        @api_map = api_map
        @cursor = cursor
        closure_pin = closure
        closure_pin.rebind(api_map) if closure_pin.is_a?(Pin::Block) && !Solargraph::Range.from_node(closure_pin.receiver).contain?(cursor.range.start)
      end

      # @return [Array<Pin::Base>] Relevant pins for infering the type of the Cursor's position
      def define
        return [] if cursor.comment? || cursor.chain.literal?
        result = cursor.chain.define(api_map, closure, locals)
        result.concat file_global_methods
        result.concat((source_map.pins + source_map.locals).select{ |p| p.name == cursor.word && p.location.range.contain?(cursor.position) }) if result.empty?
        result
      end

      # @return [Array<Pin::Base>]
      def types
        infer.namespaces.map { |namespace| api_map.get_path_pins(namespace) }.flatten
      end

      # @return [Completion]
      def complete
        logger.debug { "Clip#complete() - #{cursor.word}" }
        return package_completions([]) if !source_map.source.parsed? || cursor.string?
        return package_completions(api_map.get_symbols) if cursor.chain.literal? && cursor.chain.links.last.word == '<Symbol>'
        if cursor.chain.literal?
          out = Completion.new([], cursor.range)
          logger.debug { "Clip#complete() => #{out} - literal" }
          return out
        end
        if cursor.comment?
          logger.debug { "Clip#complete() => #{tag_complete} - comment" }
          tag_complete
        else
          logger.debug { "Clip#complete() => #{code_complete.inspect} - !comment" }
          code_complete
        end
      end

      # @return [Array<Pin::Method>]
      def signify
        return [] unless cursor.argument?
        chain = Parser.chain(cursor.recipient_node, cursor.filename)
        chain.define(api_map, context_pin, locals).select { |pin| pin.is_a?(Pin::Method) }
      end

      # @return [ComplexType]
      def infer
        result = cursor.chain.infer(api_map, closure, locals)
        if result.tag == 'Class'
          # HACK: Exception to return BasicObject from Class#new
          dfn = cursor.chain.define(api_map, closure, locals).first
          return ComplexType.try_parse('::BasicObject') if dfn && dfn.path == 'Class#new'
        end
        # should receive result with selfs resolved from infer()
        Solargraph.assert_or_log(:clip_infer_self, 'Received selfy inference') if result.selfy?
        result
      end

      # Get an array of all the locals that are visible from the cursors's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [::Array<Solargraph::Pin::LocalVariable>]
      def locals
        @locals ||= source_map.locals_at(location)
      end

      # @return [::Array<String>]
      def gates
        closure.gates
      end

      # @param phrase [String]
      # @return [Array<Solargraph::Pin::Base>]
      def translate phrase
        chain = Parser.chain(Parser.parse(phrase))
        chain.define(api_map, closure, locals)
      end

      include Logging

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [Source::Cursor]
      attr_reader :cursor

      # @return [SourceMap]
      def source_map
        @source_map ||= api_map.source_map(cursor.filename)
      end

      # @return [Location]
      def location
        Location.new(source_map.filename, Solargraph::Range.new(cursor.position, cursor.position))
      end

      # @return [Solargraph::Pin::Closure]
      def closure
        @closure ||= source_map.locate_closure_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # The context at the current position.
      #
      # @return [Pin::Base]
      def context_pin
        @context_pin ||= source_map.locate_named_path_pin(cursor.node_position.line, cursor.node_position.character)
      end

      # @return [Array<Pin::KeywordParam>]
      def complete_keyword_parameters
        return [] unless cursor.argument? && cursor.chain.links.one? && cursor.word =~ /^[a-z0-9_]*:?$/
        pins = signify
        result = []
        done = []
        pins.each do |pin|
          pin.parameters.each do |param|
            next if done.include?(param.name)
            done.push param.name
            next unless param.keyword?
            result.push Pin::KeywordParam.new(pin.location, "#{param.name}:")
          end
          if !pin.parameters.empty? && pin.parameters.last.kwrestarg?
            pin.docstring.tags(:param).each do |tag|
              next if done.include?(tag.name)
              done.push tag.name
              result.push Pin::KeywordParam.new(pin.location, "#{tag.name}:")
            end
          end
        end
        result
      end

      # @param result [Enumerable<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = cursor.start_of_word.to_s.downcase
        filtered = result.uniq(&:name).select { |s|
          s.name.downcase.start_with?(frag_start) &&
            (!s.is_a?(Pin::Method) || s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))
        }
        Completion.new(filtered, cursor.range)
      end

      # @return [Completion]
      def tag_complete
        result = []
        match = source_map.code[0..cursor.offset-1].match(/[\[<, ]([a-z0-9_:]*)\z/i)
        if match
          full = match[1]
          if full.include?('::')
            if full.end_with?('::')
              result.concat api_map.get_constants(full[0..-3], *gates)
            else
              result.concat api_map.get_constants(full.split('::')[0..-2].join('::'), *gates)
            end
          else
            result.concat api_map.get_constants('', full.end_with?('::') ? '' : context_pin.full_context.namespace, *gates) #.select { |pin| pin.name.start_with?(full) }
          end
        end
        package_completions(result)
      end

      # @return [Completion]
      def code_complete
        logger.debug { "Clip#code_complete() start - #{cursor.word}" }
        result = []
        result.concat complete_keyword_parameters
        if cursor.chain.constant? || cursor.start_of_constant?
          full = cursor.chain.links.first.word
          type = if cursor.chain.undefined?
            cursor.chain.base.infer(api_map, context_pin, locals)
          else
            if full.include?('::') && cursor.chain.links.length == 1
              ComplexType.try_parse(full.split('::')[0..-2].join('::'))
            elsif cursor.chain.links.length > 1
              ComplexType.try_parse(full)
            else
              ComplexType::UNDEFINED
            end
          end
          logger.debug { "Clip#code_complete() - type=#{type}" }
          if type.undefined?
            if full.include?('::')
              result.concat api_map.get_constants(full, *gates)
            else
              result.concat api_map.get_constants('', cursor.start_of_constant? ? '' : context_pin.full_context.namespace, *gates) #.select { |pin| pin.name.start_with?(full) }
            end
          else
            result.concat api_map.get_constants(type.namespace, cursor.start_of_constant? ? '' : context_pin.full_context.namespace, *gates)
          end
        else
          type = cursor.chain.base.infer(api_map, closure, locals)
          result.concat api_map.get_complex_type_methods(type, closure.binder.namespace, cursor.chain.links.length == 1)
          if cursor.chain.links.length == 1
            if cursor.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(context_pin.full_context.namespace))
            elsif cursor.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(closure.binder.namespace, closure.binder.scope))
            elsif cursor.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            end
            result.concat locals
            result.concat file_global_methods unless closure.binder.namespace.empty?
            result.concat api_map.get_constants(context_pin.context.namespace, *gates)
            result.concat api_map.get_methods(closure.binder.namespace, scope: closure.binder.scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            result.concat api_map.keyword_pins.to_a
          end
        end
        package_completions(result)
      end

      # @return [Array<Pin::Base>]
      def file_global_methods
        return [] if cursor.word.empty?
        source_map.pins.select do |pin|
          pin.is_a?(Pin::Method) && pin.namespace == '' && pin.name.start_with?(cursor.word)
        end
      end
    end
  end
end
