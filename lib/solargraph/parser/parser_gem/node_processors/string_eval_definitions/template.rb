# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        module StringEvalDefinitions
          # A string evaluation whose interpolations read parameters of the
          # method that contains it.
          #
          class Template
            # Literal source text, and variable names to substitute.
            # @return [Array<String, Symbol>]
            attr_reader :parts

            # The parameter that supplies each variable: the parameter itself,
            # or each element when the variable comes from `param.each`.
            # @return [Hash{Symbol => String}]
            attr_reader :params

            # Variables of a loop over a parameter.
            # @return [Array<Symbol>]
            attr_reader :iterated

            # Variables of a loop over a literal array, and the array's values.
            # @return [Hash{Symbol => Array<String>}]
            attr_reader :values

            # The constant the string is evaluated on as written, or nil for self.
            # @return [String, nil]
            attr_reader :target

            # The lexical namespaces for resolving the target.
            # @return [Array<String>]
            attr_reader :gates

            # :class for instance_eval, :instance otherwise.
            # @return [Symbol]
            attr_reader :scope

            # @param parts [Array<String, Symbol>]
            # @param params [Hash{Symbol => String}]
            # @param iterated [Array<Symbol>]
            # @param values [Hash{Symbol => Array<String>}]
            # @param target [String, nil]
            # @param gates [Array<String>]
            # @param scope [Symbol]
            def initialize parts:, params:, iterated:, values:, target:, gates:, scope:
              @parts = parts
              @params = params
              @iterated = iterated
              @values = values
              @target = target
              @gates = gates
              @scope = scope
            end

            # @param other [Object]
            # @return [Boolean]
            def == other
              other.is_a?(Template) && to_a == other.to_a
            end

            alias eql? ==

            # @return [Integer]
            def hash
              to_a.hash
            end

            # @return [Array]
            def to_a
              [parts, params, iterated, values, target, gates, scope]
            end

            # @param arguments [Hash{String => Array<String>}] the literal values
            #   a call passes for each parameter
            # @return [Array<String>] the generated sources, or none if there
            #   would be more than the limits allow
            def expand arguments
              choices = values.dup
              params.each do |var, param|
                passed = arguments[param] || []
                choices[var] = iterated.include?(var) ? passed : passed.first(1)
              end
              return [] unless within_limits?(choices)
              StringEvalDefinitions.combinations(choices).map { |choice| StringEvalDefinitions.substitute(parts, choice) }
            end

            private

            # Nested loops multiply: three loops over 100 values each would
            # generate a million sources.
            #
            # @param choices [Hash{Symbol => Array<String>}]
            # @return [Boolean]
            def within_limits? choices
              count = choices.values.map(&:length).inject(1, :*)
              return false if count > StringEvalDefinitions::MAX_EXPANSIONS
              bytes = parts.sum { |part| part.is_a?(String) ? part.bytesize : 0 }
              bytes * count <= StringEvalDefinitions::MAX_EXPANSION_BYTES
            end
          end
        end
      end
    end
  end
end
