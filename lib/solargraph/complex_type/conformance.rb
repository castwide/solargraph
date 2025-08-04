# frozen_string_literal: true

module Solargraph
  class ComplexType
    # Checks whether a type can be used in a given situation
    class Conformance
      # @param api_map [ApiMap]
      # @param inferred [ComplexType::UniqueType]
      # @param expected [ComplexType::UniqueType]
      # @param situation [:method_call, :return_type]
      # @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match,
      #   :allow_any_match, :allow_undefined, :allow_unresolved_generic, :allow_unmatched_interface>]
      # @param variance [:invariant, :covariant, :contravariant]
      def initialize api_map, inferred, expected,
                     situation = :method_call, rules = [],
                     variance: inferred.erased_variance(situation)
        @api_map = api_map
        @inferred = inferred
        @expected = expected
        @situation = situation
        @rules = rules
        @variance = variance
        unless expected.is_a?(UniqueType)
          raise "Expected type must be a UniqueType, got #{expected.class} in #{expected.inspect}"
        end
        return if inferred.is_a?(UniqueType)
        raise "Inferred type must be a UniqueType, got #{inferred.class} in #{inferred.inspect}"
      end

      def conforms_to_unique_type?
        unless expected.is_a?(UniqueType)
          raise "Expected type must be a UniqueType, got #{expected.class} in #{expected.inspect}"
        end
        if inferred.simplifyable_literal? && !expected.literal?
          return with_new_types(inferred.simplify_literals, expected).conforms_to_unique_type?
        end
        return true if expected.any?(&:interface?) && rules.include?(:allow_unmatched_interface)
        return true if inferred.interface? && rules.include?(:allow_unmatched_interface)

        if rules.include? :allow_reverse_match
          reversed_match = expected.conforms_to?(api_map, inferred, situation,
                                                 rules - [:allow_reverse_match],
                                                 variance: variance)
          return true if reversed_match
        end
        if expected != expected.downcast_to_literal_if_possible ||
           inferred != inferred.downcast_to_literal_if_possible
          return with_new_types(inferred.downcast_to_literal_if_possible,
                                expected.downcast_to_literal_if_possible).conforms_to_unique_type?
        end

        if rules.include?(:allow_subtype_skew) && !expected.parameters.empty?
          # parameters are not considered in this case
          return with_new_types(inferred, expected.erase_parameters).conforms_to_unique_type?
        end

        if !expected.parameters? && inferred.parameters?
          return with_new_types(inferred.erase_parameters, expected).conforms_to_unique_type?
        end

        if expected.parameters? && !inferred.parameters? && rules.include?(:allow_empty_params)
          return with_new_types(inferred, expected.erase_parameters).conforms_to_unique_type?
        end

        return true if inferred == expected

        case variance
        when :invariant
          return false unless inferred.name == expected.name
        when :covariant
          # covariant: we can pass in a more specific type

          # we contain the expected mix-in, or we have a more specific type
          return false unless api_map.type_include?(inferred.name, expected.name) ||
                              api_map.super_and_sub?(expected.name, inferred.name) ||
                              inferred.name == expected.name

        when :contravariant
          # contravariant: we can pass in a more general type

          # we contain the expected mix-in, or we have a more general type
          return false unless api_map.type_include?(inferred.name, expected.name) ||
                              api_map.super_and_sub?(inferred.name, expected.name) ||
                              inferred.name == expected.name
        else
          # :nocov:
          raise "Unknown variance: #{variance.inspect}"
          # :nocov:
        end

        return true if inferred.all_params.empty? && rules.include?(:allow_empty_params)

        # at this point we know the erased type is fine - time to look at parameters

        # there's an implicit 'any' on the expectation parameters
        # if there are none specified
        return true if expected.all_params.empty?

        unless expected.key_types.empty?
          return false if inferred.key_types.empty?

          unless ComplexType.new(inferred.key_types).conforms_to?(api_map,
                                                                  ComplexType.new(expected.key_types),
                                                                  situation,
                                                                  rules,
                                                                  variance: inferred.parameter_variance(situation))
            return false
          end
        end

        return true if expected.subtypes.empty?

        return true if expected.subtypes.any?(&:undefined?) && rules.include?(:allow_undefined)

        return true if inferred.subtypes.any?(&:undefined?) && rules.include?(:allow_undefined)

        return true if inferred.subtypes.all?(&:generic?) && rules.include?(:allow_unresolved_generic)

        return true if expected.subtypes.all?(&:generic?) && rules.include?(:allow_unresolved_generic)

        return false if inferred.subtypes.empty?

        ComplexType.new(inferred.subtypes).conforms_to?(api_map,
                                                        ComplexType.new(expected.subtypes),
                                                        situation,
                                                        rules,
                                                        variance: inferred.parameter_variance(situation))
      end

      private

      # @return [self]
      # @param inferred [ComplexType::UniqueType]
      # @param expected [ComplexType::UniqueType]
      def with_new_types inferred, expected
        self.class.new(api_map, inferred, expected, situation, rules, variance: variance)
      end

      attr_reader :api_map, :inferred, :expected, :situation, :rules, :variance
    end
  end
end
