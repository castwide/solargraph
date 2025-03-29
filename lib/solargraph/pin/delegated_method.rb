# frozen_string_literal: true

module Solargraph
  module Pin
    # A DelegatedMethod is a more complicated version of a MethodAlias that
    # allows aliasing a method from a different closure (class/module etc).
    class DelegatedMethod < Pin::Method
      # A DelegatedMethod can be constructed with either a :resolved_method
      # pin, or a :receiver_chain. When a :receiver_chain is supplied, it
      # will be used to *dynamically* resolve a receiver type within the
      # given closure/scope, and the delegated method will then be resolved
      # to a method pin on that type.
      #
      # @param method [Method, nil] an already resolved method pin.
      # @param receiver [Source::Chain, nil] the source code used to resolve the receiver for this delegated method.
      # @param name [String]
      # @param receiver_method_name [String] the method name that will be called on the receiver (defaults to :name).
      def initialize(method: nil, receiver: nil, name: method&.name, receiver_method_name: name, **splat)
        raise ArgumentError, 'either :method or :receiver is required' if (method && receiver) || (!method && !receiver)
        super(name: name, **splat)

        @receiver_chain = receiver
        @resolved_method = method
        @receiver_method_name = receiver_method_name
      end

      %i[comments parameters return_type location].each do |method|
        define_method(method) do
          @resolved_method ? @resolved_method.send(method) : super()
        end
      end

      %i[typify realize infer probe].each do |method|
        # @param api_map [ApiMap]
        define_method(method) do |api_map|
          resolve_method(api_map)
          @resolved_method ? @resolved_method.send(method, api_map) : super(api_map)
        end
      end

      # @param api_map [ApiMap]
      def resolvable?(api_map)
        resolve_method(api_map)
        !!@resolved_method
      end

      private

      # Resolves the receiver chain and method name to a method pin, resetting any previously resolution.
      #
      # @param api_map [ApiMap]
      # @return [Pin::Method, nil]
      def resolve_method api_map
        return if @resolved_method

        resolver = @receiver_chain.define(api_map, self, []).first

        unless resolver
          Solargraph.logger.warn \
            "Delegated receiver for #{path} was resolved to nil from `#{print_chain(@receiver_chain)}'"
          return
        end

        receiver_type = resolver.return_type

        return if receiver_type.undefined?

        receiver_path, method_scope =
          if @receiver_chain.constant?
            # HACK: the `return_type` of a constant is Class<Whatever>, but looking up a method expects
            # the arguments `"Whatever"` and `scope: :class`.
            [receiver_type.to_s.sub(/^Class<(.+)>$/, '\1'), :class]
          else
            [receiver_type.to_s, :instance]
          end

        method_stack = api_map.get_method_stack(receiver_path, @receiver_method_name, scope: method_scope)
        @resolved_method = method_stack.first
      end

      # helper to print a source chain as code, probably not 100% correct.
      #
      # @param chain [Source::Chain]
      # @return [String]
      def print_chain(chain)
        out = +''
        chain.links.each_with_index do |link, index|
          if index > 0
            if Source::Chain::Constant
              out << '::' unless link.word.start_with?('::')
            else
              out << '.'
            end
          end
          out << link.word
        end
        out
      end
    end
  end
end
