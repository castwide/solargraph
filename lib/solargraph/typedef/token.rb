# frozen_string_literal: true

module Solargraph
  module Typedef
    class Token
      RESERVED_NAMES = %w[nil undefined]

      attr_reader :name

      attr_reader :params

      def initialize name, *params
        @name = name
        @params = params
      end

      def expand(named_values)
        return self unless named_values[name]
        Typedef.tokenize(named_values[name])
      end

      def resolve_rooted(api_map, gates)
        self
      end

      def resolved?
        RESERVED_NAMES.include?(name)
      end

      def expanded?
        RESERVED_NAMES.include?(name)
      end

      def generic?
        name.start_with?('generic<')
      end

      # Type#any_generic? recurses into base/params, which may be a Token.
      # Token is a leaf with no sub-elements to distinguish any from all,
      # so this is just #generic? under the name Type's recursion expects.
      alias any_generic? generic?

      # @todo Token has no way to tell whether a generic placeholder like
      #   generic<T> has actually been rooted to a real namespace. Treating
      #   every Token as rooted keeps Type#rooted? from raising on params
      #   that are Tokens (e.g. a bare generic placeholder), matching how
      #   the older ComplexType::UniqueType system treats its own generic
      #   tag as always rooted.
      def rooted?
        true
      end

      # @return [Hash]
      def extract_generics token
        return {} unless generic?
        { name => token }
      end

      def to_s
        "#{([name] + params).join(', ')}"
      end

      def to_s_for_complex_type
        to_s
      end
    end
  end
end
