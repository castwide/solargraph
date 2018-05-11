module Solargraph
  module Pin
    class MethodParameter < LocalVariable
      def return_type
        if @return_type.nil? and !block.docstring.nil?
          found = nil
          params = block.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
          end
          @return_type = found.types[0] unless found.nil? or found.types.nil?
        end
        super
        @return_type
      end
    end
  end
end
