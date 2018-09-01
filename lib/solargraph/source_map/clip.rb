module Solargraph
  class SourceMap
    class Clip
      # @param api_map [ApiMap]
      # @param fragment [Fragment]
      def initialize api_map, fragment
        @api_map = api_map
        @fragment = fragment
      end

      def define
        fragment.chain.define(api_map, fragment.context, fragment.locals)
      end

      def complete
        return Completion.new([], fragment.range) if fragment.chain.literal?
        result = []
        # type = infer_base_type(api_map)
        type = fragment.chain.base.infer(api_map, fragment.context, fragment.locals)
        if fragment.chain.constant?
          result.concat api_map.get_constants(type.namespace, fragment.context.namespace)
        else
          result.concat api_map.get_complex_type_methods(type, fragment.context.namespace, fragment.chain.links.length == 1)
          if fragment.chain.links.length == 1
            if fragment.word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(fragment.context.namespace))
            elsif fragment.word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(fragment.context.namespace, fragment.context.scope))
            elsif fragment.word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            elsif fragment.word.start_with?(':') and !fragment.word.start_with?('::')
              return package_completions(api_map.get_symbols)
            end
            result.concat api_map.get_constants('', fragment.context.namespace)
            result.concat prefer_non_nil_variables(fragment.locals)
            result.concat api_map.get_methods(fragment.context.namespace, scope: fragment.context.scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            result.concat ApiMap.keywords
          end
        end
        package_completions(result)
      end

      def signify
        return [] unless fragment.argument?
        clip = Clip.new(api_map, fragment.recipient)
        clip.define.select{|pin| pin.kind == Pin::METHOD}
      end

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [Fragment]
      attr_reader :fragment

      # @param fragment [Source::Fragment]
      # @param result [Array<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = fragment.word.to_s.downcase
        filtered = result.uniq(&:identifier).select{|s| s.name.downcase.start_with?(frag_start) and (s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))}.sort_by.with_index{ |x, idx| [x.name, idx] }
        Completion.new(filtered, fragment.range)
      end

      # Sort an array of pins to put nil or undefined variables last.
      #
      # @param pins [Array<Solargraph::Pin::Base>]
      # @return [Array<Solargraph::Pin::Base>]
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
