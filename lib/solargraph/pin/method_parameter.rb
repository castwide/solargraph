module Solargraph
  module Pin
    class MethodParameter < LocalVariable
      def initialize source, node, namespace, ancestors
        super
        # Look for the return type in the method's @param tags
        docstring = source.docstring_for(ancestors.first)
        unless docstring.nil?
          tags = docstring.tags(:param)
          tags.each do |tag|
            if tag.name == name and !tag.types.nil? and !tag.types.empty?
              @return_type = tag.types[0]
            end
          end
        end
      end
    end
  end
end
