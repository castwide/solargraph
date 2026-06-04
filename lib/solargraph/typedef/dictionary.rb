# frozen_string_literal: true

module Solargraph
  module Typedef
    # Type expansion and resolution utilities.
    #
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

      # @return [Source::Chain]
      def chain
        @chain ||= Solargraph::Source::SourceChainer.chain(source_map.source, position)
      end

      # @return [Pin::Closure]
      def closure
        @closure ||= source_map.locate_closure_pin(position.line, position.character)
      end

      # @return [Location]
      def location
        @location ||= Location.new(source_map.filename, Range.new(position, position))
      end

      # @return [Array<Pin::BaseVariable>]
      def locals
        @locals ||= source_map.locals_at(location)
      end

      # @return [Array<Pin::Base>]
      def define
        pins, _receiver = define_from chain
        pins
      end

      # @return [Typeset]
      def infer
        Typedef.memos.fetch memo_key(:infer), Typeset::UNDEFINED do
          pins, receiver = define_from chain
          return ComplexType::UNDEFINED.to_typedef_typeset if pins.empty?
          return pins.first.typedef_typeset if receiver.typedef_typeset.to_s == pins.first.typedef_typeset.to_s && pins.first.typedef_typeset.to_s != 'undefined'

          proxies = infer_proxies(pins, receiver)
          inferred = proxies.find { |pin| pin.typedef_typeset.to_s != 'undefined' }
          return inferred.typedef_typeset if inferred

          ComplexType::UNDEFINED.to_typedef_typeset
        end
      end

      # @param [Source::Chain]
      # @return [Array(Array<Pin::Base>, Pin::Closure)]
      def define_from chain
        Typedef.memos.fetch memo_key(:define), [[], nil] do
          next [[closure], closure.closure] if chain.undefined?

          pins = []
          receiver = closure
          last_link = chain.links.last
          chain.links.each do |link|
            pins = hitch(link, receiver)
            break if link == last_link

            proxies = infer_proxies(pins, receiver)
            return [[], receiver] if proxies.empty?
            receiver = proxies.first
            return [[], nil] unless receiver
          end
          [pins, receiver]
        end
      end

      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure, nil]
      # @return [Array<Pin::ProxyType>]
      def infer_proxies pins, receiver
        return pins unless receiver # @todo Why is this necessary?

        # @todo This is inefficient. We probably only need to find and return the first pin that isn't undefined,
        #   or undefined otherwise
        result = pins.flat_map { |pin| pin.is_a?(Pin::Callable) ? find_matching_signature(pin, receiver) : pin }
            .map { |pin| root_and_infer(pin, receiver) }
            .map { |pin| expand_generics(pin, receiver) }
            # @todo It might make more sense to root after expanding generics
            # .map { |pin| root_and_infer(pin, receiver) }
        # @todo Making a proxy for undefined types seems inefficient
        [result.first || Pin::ProxyType.anonymous(ComplexType::UNDEFINED)]
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::Base]
      def expand_generics pin, receiver
        typeset = Generics.expand(api_map, pin, receiver)
                        # @todo There might be a better place for this
                        .expand({ 'self' => receiver.namespace })

        pin.proxy(typeset.to_complex_type)
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure, Pin::ProxyType]
      # @return [Typeset]
      def resolve_rooted pin, receiver
        pin.typedef_typeset.resolve_rooted(api_map, receiver&.closure&.gates || [''])
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::ProxyType]
      def root_and_infer pin, receiver
        rooted = resolve_rooted(pin, receiver)
        inferred = if rooted.to_s == 'undefined' # @todo Better way to identify undefined
          infer_by_pin_type pin, receiver
        else
          rooted
        end
        expanded = expand_generic_parameters(inferred, pin, receiver)
        Pin::ProxyType.anonymous(expanded.to_complex_type)
      end

      # @return [Typeset]
      def infer_by_pin_type pin, receiver
        case pin
        when Pin::BaseVariable, Pin::Constant
          chain = Solargraph::Parser::ParserGem::NodeChainer.chain(pin.assignment)
          Dictionary.new(api_map, pin.filename, pin.location.range.start, chain: chain).infer
        else
          next_chain = next_chain(pin)
          return pin.typedef_typeset unless next_chain
          Dictionary.new(api_map, pin.filename, Range.from_node(next_chain.node).start, chain: next_chain).infer
        end
      end

      # @param pin [Pin::Base]
      # @return [Source::Chain, nil]
      def next_chain(pin)
        return unless pin.location

        if pin.location.range.start != position
          return Parser::ParserGem::NodeChainer.chain(source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column))
        elsif pin.is_a?(Pin::Callable)
          node = method_body_node(pin)
          Parser::ParserGem::NodeChainer.chain(node) if node
        elsif pin.is_a?(Pin::BaseVariable)
          Parser::ParserGem::NodeChainer.chain(pin.assignment)
        else
          nil
        end
      end

      # @return [Parser::AST::Node, nil]
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
      def find_matching_signature(pin, receiver)
        pin.signatures.each do |signature|
          # @todo Match on more precise criteria than mere argument length
          next unless signature.arity_matches?(chain.links.last.arguments, chain.links.last.with_block?)

          expanded = Generics.expand(api_map, signature, receiver)
          return signature.proxy(expanded.to_complex_type)
        end
        expanded = Generics.expand(api_map, pin, receiver)
        return pin.proxy(expanded.to_complex_type)
      end

      # @param typeset [Typeset]
      # @param pin [Pin::Base]
      # @param receiver [Pin::Base]
      # @return [Typeset]
      def expand_generic_parameters typeset, pin, receiver
        case pin
        when Pin::BaseVariable
          expand_generic_parameters_from_variable(typeset, pin, receiver)
        else
          typeset
        end
      end

      # @param typeset [Typeset]
      # @param pin [Pin::BaseVariable]
      # @param receiver [Pin::Base]
      # @return [Typeset]
      def expand_generic_parameters_from_variable(typeset, pin, receiver)
        return typeset unless pin.assignment

        chain = Parser::ParserGem::NodeChainer.chain(pin.assignment)
        return typeset unless chain.links.last.is_a?(Source::Chain::Call)

        defined = Dictionary.new(api_map, pin.filename, pin.location.range.start, chain: chain).define.find { |pin| pin.is_a?(Pin::Callable) }
        return typeset unless defined

        final = typeset
        chain.links.last.arguments.each do |arg|
          inferred = Dictionary.new(api_map, pin.filename, pin.location.range.start, chain: arg).infer
          expanded = Generics.expand(api_map, defined, Pin::ProxyType.anonymous(inferred.to_complex_type))
          final = expanded
        end
        final
      end

      def memo_key(action)
        [source_map.filename, [api_map, position, chain, action]]
      end
    end
  end
end
