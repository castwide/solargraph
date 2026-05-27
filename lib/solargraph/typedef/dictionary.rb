# frozen_string_literal: true

module Solargraph
  module Typedef
    # Temporary utilities for using typedef in chain inference.
    class Dictionary
      include Linker

      attr_reader :api_map

      attr_reader :source_map

      attr_reader :position

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer), nil]
      def initialize api_map, source_map, position, chain: nil, closure: nil
        @api_map = api_map
        @source_map = source_map.is_a?(SourceMap) ? source_map : api_map.source_map(source_map)
        @position = Solargraph::Position.normalize(position) if position
        @chain = chain
        @closure = closure
      end

      def chain
        @chain ||= Solargraph::Source::SourceChainer.chain(source_map.source, position)
      end

      def closure
        @closure ||= source_map.locate_closure_pin(position.line, position.character)
      end

      def location
        @location ||= Location.new(source_map.filename, Range.new(position, position))
      end

      def locals
        @locals ||= source_map.locals_at(location)
      end

      # @return [Array<Pin::Base>]
      def define
        pins, _receiver = define_from chain
        pins
      end

      # @return [Array<Typedef::Type>]
      def infer
        Typedef.memos.fetch memo_key(:infer), [] do
          pins, receiver = define_from chain
          proxies = infer_proxies(pins, receiver)
          # @todo Smelly uniqueness
          proxies.flat_map(&:typedef_return_types).uniq(&:to_s)
        end
      end

      # @param [Source::Chain]
      # @return [Array(Array<Pin::Base>, Pin::Closure)]
      def define_from chain
        Typedef.memos.fetch memo_key(:define), [[], nil] do
          next [[closure], closure.closure] if chain.undefined?

          pins = []
          current_closure = closure
          last_link = chain.links.last
          chain.links.each do |link|
            pins = hitch(link, current_closure).map { |pin| expand_tokens(pin, current_closure) }
            next pins, current_closure if link == last_link

            proxies = infer_proxies(pins, current_closure)
            break [[], current_closure] if proxies.empty?
            current_closure = proxies.first
            break [[], nil] unless current_closure
          end
          [pins, current_closure]
        end
      end

      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure, nil]
      # @return [Array<Pin::ProxyType>]
      def infer_proxies pins, receiver
        return pins unless receiver

        pins.flat_map { |pin| pin.is_a?(Pin::Method) ? find_matching_signature(pin) : pin }
            .map { |pin| root_and_infer(pin, receiver) }
            .map { |pin| expand_tokens(pin, receiver) }
            .map { |pin| Pin::ProxyType.anonymous(ComplexType.new(pin.typedef_return_types.map(&:to_complex_type))) }
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::Base]
      def expand_tokens pin, receiver
        expanded = expand_generic_types(pin, receiver)
        pin.proxy(ComplexType.new(expanded.map(&:to_complex_type)))
      end

      def expand_generic_types pin, receiver
        namespaces = api_map.get_path_pins(receiver.namespace).select { |pin| pin.is_a?(Pin::Namespace) }
        generic_names = namespaces.flat_map(&:generics).map { |name| "generic<#{name}>"}
        return pin.typedef_return_types if generic_names.empty?

        type = receiver.typedef_return_types.find { |type| type.base.to_s == receiver.namespace && type.params.length == generic_names.length }
        return pin.typedef_return_types unless type

        named_values = generic_names.zip(type.params).to_h
                                    .merge({ 'self' => receiver.binder.namespace })
        pin.typedef_return_types.map do |type|
          next type unless type.generic?

          type.expand(named_values)
        end        
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::ProxyType]
      def root_and_infer pin, receiver
        inferred = pin.typedef_return_types.flat_map do |type|
          rooted = type.resolve_rooted(api_map, receiver&.closure&.gates || [''])
          if rooted.base.to_s == 'undefined' # @todo Better way to identify undefined
            next_chain = next_chain(pin)
            next rooted unless next_chain
            Dictionary.new(api_map, pin.filename, Range.from_node(next_chain.node).start, chain: next_chain).infer
          else
            rooted
          end
        end
        Pin::ProxyType.anonymous(ComplexType.new(inferred.map(&:to_complex_type)))
      end

      # @param pin [Pin::Base]
      # @return [Source::Chain, nil]
      def next_chain(pin)
        return unless pin.location

        if pin.location.range.start != position
          return Parser::ParserGem::NodeChainer.chain(source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column))
        elsif pin.is_a?(Pin::Method)
          node = method_body_node(pin)
          Parser::ParserGem::NodeChainer.chain(node) if node
        elsif pin.is_a?(Pin::BaseVariable)
          Parser::ParserGem::NodeChainer.chain(pin.assignment)
        else
          nil
        end
      end

      def method_body_node(pin)
        node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
        return unless node
        return node.children[1].children.last if node.type == :DEFN
        return node.children[2].children.last if node.type == :DEFS
        return node.children[2] if %i[def DEFS].include?(node.type)
        return node.children[3] if node.type == :defs
      end

      # @todo Either implement this or (more likely) handle it in Linker::Call
      # @param pin [Pin::Method]
      # @return [Pin::Signature, Pin::Method]
      def find_matching_signature(pin)
        pin.signatures.find do |sig|
          # puts "Check against #{chain.inspect}"
          false
        end || pin
      end

      def memo_key(action)
        [source_map.filename, [api_map, position, chain, action]]
      end
    end
  end
end
