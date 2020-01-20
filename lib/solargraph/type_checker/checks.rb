module Solargraph
  class TypeChecker
    module Checks
      module_function

      # Compare an expected type with an inferred type. Common usage is to
      # check if the type declared in a method's @return tag matches the type
      # inferred from static analysis of the code.
      #
      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def types_match? api_map, expected, inferred
        return true if expected.to_s == inferred.to_s
        matches = []
        expected.each do |exp|
          found = false
          inferred.each do |inf|
            if api_map.super_and_sub?(*fuzz_pair(exp, inf))
              found = true
              matches.push inf
              break
            end
          end
          return false unless found
        end
        inferred.each do |inf|
          next if matches.include?(inf)
          found = false
          expected.each do |exp|
            if api_map.super_and_sub?(*fuzz_pair(exp, inf))
              found = true
              break
            end
          end
          return false unless found
        end
        true
      end

      # @param type1 [ComplexType]
      # @param type2 [ComplexType]
      # @return [String]
      def fuzz_pair type1, type2
        # if type1.name == 'Class' && type2.name == 'Class'
        #   [
        #     (type1.parameters? ? type1.namespace : 'Object'),
        #     (type2.parameters? ? type2.namespace : 'Object')
        #   ]
        # else
          [fuzz(type1), fuzz(type2)]
        # end
      end

      # @param type [ComplexType]
      # @return [String]
      def fuzz type
        if type.parameters?
          type.name
        else
          type.tag
        end
      end
    end
  end
end
