# frozen_string_literal: true

module Solargraph
  # Convert RBS::Types to ComplexTypes.
  #
  module RbsToComplex
    # @param type [RBS::Types::Bases::Base]
    # @return [ComplexType]
    def self.convert type
      tag = type_to_tag(type)
      ComplexType.try_parse(tag)
    end

    class << self
      private

      # @param type [RBS::Types::Bases::Base]
      # @return [String]
      def type_to_tag type
        if type.is_a?(RBS::Types::Optional)
          "#{type_to_tag(type.type)}, nil"
        elsif type.is_a?(RBS::Types::Bases::Any)
          'undefined'
        elsif type.is_a?(RBS::Types::Bases::Bool)
          'Boolean'
        elsif type.is_a?(RBS::Types::Tuple)
          "Array(#{type.types.map { |t| type_to_tag(t) }.join(', ')})"
        elsif type.is_a?(RBS::Types::Literal)
          type.literal.inspect
        elsif type.is_a?(RBS::Types::Union)
          type.types.map { |t| type_to_tag(t) }.join(', ')
        elsif type.is_a?(RBS::Types::Record)
          # @todo Better record support
          'Hash'
        elsif type.is_a?(RBS::Types::Bases::Nil)
          'nil'
        elsif type.is_a?(RBS::Types::Bases::Self)
          'self'
        elsif type.is_a?(RBS::Types::Bases::Void)
          'void'
        elsif type.is_a?(RBS::Types::Variable)
          "#{Solargraph::ComplexType::GENERIC_TAG_NAME}<#{type.name}>"
        elsif type.is_a?(RBS::Types::ClassInstance) # && !type.args.empty?
          type_tag(type.name, type.args)
        elsif type.is_a?(RBS::Types::Bases::Instance)
          'self'
        elsif type.is_a?(RBS::Types::Bases::Top)
          # top is the most super superclass
          'BasicObject'
        elsif type.is_a?(RBS::Types::Bases::Bottom)
          # bottom is used in contexts where nothing will ever return
          # - e.g., it could be the return type of 'exit()' or 'raise'
          #
          # @todo define a specific bottom type and use it to
          #   determine dead code
          'undefined'
        elsif type.is_a?(RBS::Types::Intersection)
          type.types.map { |member| type_to_tag(member) }.join(', ')
        elsif type.is_a?(RBS::Types::Proc)
          'Proc'
        elsif type.is_a?(RBS::Types::Alias)
          # type-level alias use - e.g., 'bool' in "type bool = true | false"
          # @todo ensure these get resolved after processing all aliases
          # @todo handle recursive aliases
          type_tag(type.name, type.args)
        elsif type.is_a?(RBS::Types::Interface)
          # represents a mix-in module which can be considered a
          # subtype of a consumer of it
          type_tag(type.name, type.args)
        elsif type.is_a?(RBS::Types::ClassSingleton)
          # e.g., singleton(String)
          type_tag(type.name)
        else
          Solargraph.logger.warn "Unrecognized RBS type: #{type.class} at #{type.location}"
          'undefined'
        end
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @return [String]
      def type_tag(type_name, type_args = [])
        build_type(type_name, type_args).tags
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @return [ComplexType::UniqueType]
      def build_type(type_name, type_args = [])
        base = RbsMap::Conversions::RBS_TO_YARD_TYPE[type_name.relative!.to_s] || type_name.relative!.to_s
        params = type_args.map { |a| type_to_tag(a) }.map do |t|
          ComplexType.try_parse(t).force_rooted
        end
        if base == 'Hash' && params.length == 2
          ComplexType::UniqueType.new(base, [params.first], [params.last], rooted: true, parameters_type: :hash)
        else
          ComplexType::UniqueType.new(base, [], params.reject(&:undefined?), rooted: true, parameters_type: :list)
        end
      end
    end
  end
end
