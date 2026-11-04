# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Hash < Literal
        # @param type [String]
        # @param node [Parser::AST::Node]
        # @param splatted [Boolean]
        # @param pairs [::Array<::Array(Chain, Chain)>, nil] Chained key/value
        #   pairs, or nil for a splatted or non-plain-pairs literal - see
        #   NodeChainer#hash_pairs.
        def initialize type, node, splatted = false, pairs = nil
          super(type, node)
          @splatted = splatted
          @pairs = pairs
        end

        def word
          @word ||= "<#{@type}>"
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          [Pin::ProxyType.anonymous(inferred_type(api_map, name_pin, locals), source: :chain)]
        end

        def splatted?
          @splatted
        end

        protected

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        def equality_fields
          # @sg-ignore literal arrays in this module turn into ::Solargraph::Source::Chain::Array
          super + [@splatted]
        end

        private

        # Infers Hash{K => V} from the literal's pairs, mirroring
        # Chain::Array's element inference. Falls back to bare ::Hash
        # when splatted or any pair fails to infer.
        #
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        # @return [ComplexType]
        def inferred_type api_map, name_pin, locals
          pairs = @pairs
          return @complex_type if pairs.nil? || pairs.empty?

          # @type [::Array<ComplexType>]
          key_types = []
          # @type [::Array<ComplexType>]
          value_types = []
          pairs.each do |pair|
            key_chain, value_chain = pair
            key_type = key_chain.infer(api_map, name_pin, locals).simplify_literals
            value_type = value_chain.infer(api_map, name_pin, locals).simplify_literals
            return @complex_type if key_type.undefined? || value_type.undefined?

            key_types.push key_type
            value_types.push value_type
          end
          ComplexType.new([ComplexType::UniqueType.new('Hash', key_types.uniq, value_types.uniq,
                                                       rooted: true, parameters_type: :hash)])
        end
      end
    end
  end
end
