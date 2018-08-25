module Solargraph
  module Pin
    class MethodParameter < LocalVariable
      def return_complex_type
        if @return_complex_type.nil?
          @return_complex_type = ComplexType.new
          found = nil
          params = block.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
          end
          @return_complex_type = ComplexType.parse(*found.types) unless found.nil? or found.types.nil?
        end
        super
        @return_complex_type
      end

      def try_merge! pin
        return false unless super
        # @todo This is a little expensive, but it's necessary because
        #   parameter data depends on the method's docstring.
        @return_complex_type = pin.return_complex_type
        reset_conversions
        true
      end
    end
  end
end
