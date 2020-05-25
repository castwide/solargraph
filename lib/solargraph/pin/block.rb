# frozen_string_literal: true

module Solargraph
  module Pin
    class Block < Closure
      # The signature of the method that receives this block.
      #
      # @return [Parser::AST::Node]
      attr_reader :receiver

      def initialize receiver: nil, args: [], **splat
        super(**splat)
        @receiver = receiver
        @parameters = args
      end

      def rebind api_map
        @binder ||= binder_or_nil(api_map)
      end

      # @return [Array<String>]
      def parameters
        @parameters ||= []
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      private

      def skippable_block_receivers api_map
        @@skippable_block_receivers ||= (
          api_map.get_methods('Array', deep: false).map(&:name) +
          api_map.get_methods('Enumerable', deep: false).map(&:name) +
          api_map.get_methods('Hash', deep: false).map(&:name) +
          ['new']
        ).to_set
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def binder_or_nil api_map
        return nil unless receiver
        chain = Parser.chain(receiver, location.filename)
        return nil if skippable_block_receivers(api_map).include?(chain.links.last.word)
        locals = api_map.source_map(location.filename).locals_at(location)
        if ['instance_eval', 'instance_exec', 'class_eval', 'class_exec', 'module_eval', 'module_exec'].include?(chain.links.last.word)
          return chain.base.infer(api_map, self, locals)
        else
          receiver_pin = chain.define(api_map, self, locals).first
          if receiver_pin && receiver_pin.docstring
            ys = receiver_pin.docstring.tag(:yieldself)
            if ys && ys.types && !ys.types.empty?
              return ComplexType.try_parse(*ys.types).qualify(api_map, receiver_pin.context.namespace)
            end
          end
        end
        nil
      end
    end
  end
end
