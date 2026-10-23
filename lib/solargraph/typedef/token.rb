# frozen_string_literal: true

module Solargraph
  module Typedef
    class Token
      RESERVED_NAMES = %w[nil undefined].freeze

      attr_reader :name, :params

      def initialize name, *params
        @name = name
        @params = params
      end

      def expand named_values
        return self unless named_values[name]
        if name == 'self' && named_values[name].is_a?(Typedef::Typeset)
          Typedef::Typeset.new(named_values[name].types.map do |type|
            if %w[Class Module].include?(type.base.name)
              if type.params.empty?
                Typeset::UNDEFINED
              else
                Typedef::Typeset.new(type.params)
              end
            else
              Typedef.tokenize(type)
            end
          end)
        else
          Typedef.tokenize(named_values[name])
        end
      end

      def resolve_rooted api_map, gates
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

      def extract_generics token
        return unless generic?
        { name => token }
      end

      def to_s
        ([name] + params).join(', ')
      end

      def to_s_for_complex_type
        to_s
      end
    end
  end
end
