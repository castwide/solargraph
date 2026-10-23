# frozen_string_literal: true

module Solargraph
  module Typedef
    # Type expansion and resolution utilities.
    #
    class Dictionary
      include Linker

      # @return [ApiMap]
      attr_reader :api_map

      # @return [SourceMap]
      attr_reader :source_map

      # @return [Position]
      attr_reader :position

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer), nil]
      # @param chain [Source::Chain, nil]
      # @param closure [Pin::Closure, nil]
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
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:define), [[], nil] do
          pins, receiver = define_from_chain
          pins.map { |pin| pin.proxy(Expansions::Macros.expand(api_map, pin, receiver).to_complex_type) }
        end
      end

      # @return [Typeset]
      def infer
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:infer), Typeset::UNDEFINED do
          pins, receiver = define_from_chain
          return ComplexType::UNDEFINED.to_typedef_typeset if pins.empty?

          proxies = infer_proxies(pins, receiver)
          inferred = proxies.find { |pin| pin.typedef_typeset.to_s != 'undefined' }
          return inferred.typedef_typeset if inferred

          ComplexType::UNDEFINED.to_typedef_typeset
        end
      end

      private

      # @param chain [Source::Chain]
      # @return [Array<Pin::Base>, Pin::Closure)]
      def define_from_chain
        return [[closure], closure.closure] if chain.undefined?

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

      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure]
      # @return [Array<Pin::ProxyType>]
      def infer_proxies pins, receiver
        expanded = if receiver
                     pins.map { |pin| pin.proxy(Expansions::Generics.expand(api_map, pin, receiver).to_complex_type) }
                         .map { |pin| pin.proxy(resolve_rooted(pin, receiver).to_complex_type) }
                         .map { |pin| expand_self(pin, receiver) }
                   else
                     pins
                   end

        result = expanded.map { |pin| deep_infer(pin, receiver) }

        # @todo Find the first pin with a defined type?
        # @todo Making a proxy for undefined types seems inefficient
        [result.first || Pin::ProxyType.anonymous(ComplexType::UNDEFINED)]
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure, Pin::ProxyType]
      # @return [Typeset]
      def resolve_rooted pin, receiver
        pin.typedef_typeset.resolve_rooted(api_map, receiver&.closure&.gates || [''])
      end

      def expand_self pin, receiver
        # @todo A Class#new exception is necessary because the current pin from
        #   RBS core has return type `undefined`. A better solution is a
        #   CoreFills override of `Class#new => self`, but it interferes with
        #   the existing chain inference.
        if pin.path == 'Class#new'
          pin.proxy(Solargraph::ComplexType.parse('::Class'))
        else
          pin.proxy(pin.typedef_typeset.expand({ 'self' => receiver.typedef_typeset }).to_complex_type)
        end
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::Base]
      def deep_infer pin, receiver
        typeset = pin.typedef_typeset
        inferred = if typeset.to_s == 'undefined' # @todo Better way to identify undefined
                     infer_by_pin_type pin, receiver
                   else
                     typeset
                   end
        # @todo Not sure why this has to be an anonymous proxy, proxying the pin directly
        #   breaks a whole lot of stuff
        Pin::ProxyType.anonymous(inferred.to_complex_type)
      end

      # @return [Typeset]
      def infer_by_pin_type pin, receiver
        return infer_from_block_receiver(pin, receiver) if receiver.is_a?(Pin::Block)

        case pin
        when Pin::BaseVariable, Pin::Constant
          return_types_from_node(pin.assignment)
        # when Pin::Callable
        #   return_types_from_node(real_method_body_node(pin))
        else
          # next_chain = next_chain(pin)
          # return pin.typedef_typeset unless next_chain
          # Dictionary.new(api_map, pin.filename, Range.from_node(next_chain.node).start, chain: next_chain).infer
          next_node = next_node(pin)
          return_types_from_node(next_node)
        end
      end

      def infer_from_block_receiver pin, receiver
        # @todo For now, we assume that an undefined typeset from call chain
        #   inference requires a type to be inferred from the block chain. We
        #   might need to make it more accurate, e.g., the call chain should
        #   be calling the native `yield` method or `call` on a block parameter.
        next_chain = next_chain(pin)
        if next_chain
          chain_inferred = Dictionary.new(api_map, pin.filename, Range.from_node(next_chain.node).start, chain: next_chain).infer
          return chain_inferred unless chain_inferred.to_s == 'undefined' || chain_inferred.to_s.empty?
        end

        call_chain = Solargraph::Parser::ParserGem::NodeChainer.chain(receiver.node)
        Dictionary.new(api_map, pin.filename, receiver.location.range.start, chain: call_chain.links.last.block).infer
      end

      # @param pin [Pin::Base]
      # @return [Source::Chain, nil]
      def next_chain pin
        return unless pin.location

        if pin.location.range.start != position
          Parser::ParserGem::NodeChainer.chain(source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column))
        elsif pin.is_a?(Pin::Callable)
          node = method_body_node(pin)
          Parser::ParserGem::NodeChainer.chain(node) if node
        end
      end

      def next_node pin
        if pin.is_a?(Pin::Method)
          method_body_node(pin)
        else
          return unless pin.location
          source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
        end
      end

      # @param pin [Pin::Base]
      # @return [Parser::AST::Node, nil]
      def method_body_node pin
        # node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
        node = pin.node
        return unless node
        return node.children[1].children.last if node.type == :DEFN
        return node.children[2].children.last if node.type == :DEFS
        return node.children[2] if %i[def DEFS].include?(node.type)
        node.children[3] if node.type == :defs
      end

      def real_method_body_node pin
        node = pin.node
        return unless node
        return node.children[1].children.last if node.type == :DEFN
        return node.children[2].children.last if node.type == :DEFS
        return node.children[2] if %i[def DEFS].include?(node.type)
        node.children[3] if node.type == :defs
      end

      # @param parent_node [Parser::AST::Node]
      # @return [Typeset]
      def return_types_from_node parent_node
        types = []
        Parser::ParserGem::NodeMethods.value_position_nodes_only(parent_node).each do |node|
          # Nil nodes may not have a location
          if node.nil? || node.type == :NIL || node.type == :nil
            types.push ComplexType::NIL.to_typedef_typeset
          else
            rng = Range.from_node(node)
            next if rng.nil?
            pos = rng.ending
            chain = Parser.chain(node, nil, nil)
            result = Dictionary.new(api_map, source_map, pos, chain: chain).infer
            types.push result
          end
        end
        return ComplexType::UNDEFINED.to_typedef_typeset if types.empty?
        Typeset.new(types)
      rescue FileNotFoundError
        # @todo Necessary for pins from source maps that are not part of the workspace
        [ComplexType::UNDEFINED]
      end

      # @param action [Symbol]
      # @return [Key]
      def memo_key action
        Memoizer::Key.new(filename: source_map.filename, api_map: api_map, position: position, chain: chain, action: action)
      end
    end
  end
end
