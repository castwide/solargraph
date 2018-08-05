module Solargraph
  module Pin
    class MethodParameter < LocalVariable
      def return_complex_types
        if @return_complex_types.nil?
          @return_complex_types = []
          unless block.docstring.nil?
            found = nil
            params = block.docstring.tags(:param)
            params.each do |p|
              next unless p.name == name
              found = p
            end
            @return_complex_types.concat ComplexType.parse(*found.types) unless found.nil? or found.types.nil?
          end
        end
        super
        @return_complex_types
      end
    end
  end
end
