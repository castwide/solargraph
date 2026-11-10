# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Expansion of code with block receivers.
      #
      class Block < Base
        def expand
          case pin
          when Pin::Parameter
            signature_type || yieldparam_type || ComplexType::UNDEFINED.to_typedef_typeset
          else
            node = source_map.source.node_at(pin.location.range.start.line, pin.location.range.start.column)
            call_chain = Parser.chain(node)
            chain_inferred = Dictionary.new(api_map, pin.filename, call_chain).infer
            return chain_inferred unless chain_inferred.undefined? || chain_inferred.to_s.empty?

            call_chain = Solargraph::Parser::ParserGem::NodeChainer.chain(receiver.node)
            Dictionary.new(api_map, pin.filename, call_chain.links.last.block).infer
          end
        end

        private

        def source_map
          api_map.source_map(pin.filename)
        end

        def signature_pins
          @signature_pins ||= Dictionary.new(api_map, pin.filename, Parser.chain(receiver.node)).define
        end

        def argument_index
          @argument_index ||= receiver.parameters.find_index { |param| param.name == pin.name }
        end

        def signature_type
          return nil unless argument_index
          signature_pins.each do |pin|
            next unless pin.block
            parameter = pin.block.parameters[argument_index]
            next unless parameter&.return_type&.defined?
            expanded = parameter.typedef_typeset.expand(signature_generic_values(pin))
            return expanded if expanded.defined?
          end
          nil
        end

        # Generic values for the signature block's receiver-side type
        # parameters, e.g. binding the element type of Enumerable when a
        # block is passed to Enumerable#map.
        #
        # @param pin [Pin::Base]
        # @return [Hash{String => Object}]
        def signature_generic_values pin
          @signature_generic_values ||= {}
          return @signature_generic_values[pin] if @signature_generic_values.key?(pin)
          typeset = receiver_typeset
          values = if typeset.defined?
                     Expansions::Generics.new(api_map, pin, Pin::ProxyType.anonymous(typeset.to_complex_type)).closure_generic_values
                   else
                     {}
                   end
          @signature_generic_values[pin] = values
        end

        # The type of the expression receiving the block, e.g. the type of
        # +pins+ in +pins.map { ... }+.
        #
        # @return [Typeset]
        def receiver_typeset
          @receiver_typeset ||= begin
            receiver_node = receiver_receiver_node
            if receiver_node
              Dictionary.new(api_map, pin.filename, Parser.chain(receiver_node)).infer
            else
              ComplexType::UNDEFINED.to_typedef_typeset
            end
          rescue StandardError => _e
            ComplexType::UNDEFINED.to_typedef_typeset
          end
        end

        # The AST node for the receiver of the call that takes the block.
        # The block pin's receiver is the call node, e.g. +pins.map+ in
        # +pins.map { |p| p }+. A method call node holds its receiver in
        # the first child.
        #
        # @return [Parser::AST::Node, nil]
        def receiver_receiver_node
          call = receiver.receiver
          return nil unless call
          call = call.children.first if call.type == :block
          return nil unless call.respond_to?(:children)
          call.type == :lit ? nil : call.children.first
        end

        def method_pins
          @method_pins ||= Dictionary.new(api_map, pin.filename, Parser.chain(receiver.receiver)).define
        end

        def yieldparam_tags
          @yieldparam_tags ||= method_pins.find { |pin| pin.docstring.tags(:yieldparam).any? }
                                          &.docstring&.tags(:yieldparam) || []
        end

        def yieldparam_matching_tag
          @yieldparam_matching_tag ||= yieldparam_tags[receiver.parameters.find_index { |param| param.name == pin.name }]
        end

        def yieldparam_type
          @yieldparam_type ||= ComplexType.parse(yieldparam_matching_tag.type).to_typedef_typeset if yieldparam_matching_tag
        end
      end
    end
  end
end
