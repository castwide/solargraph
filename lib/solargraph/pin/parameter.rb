module Solargraph
  module Pin
    class Parameter < LocalVariable
      def return_type
        if @return_type.nil?
          @return_type = ComplexType.new
          found = nil
          # params = block.docstring.tags(:param)
          params = closure.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
            break
          end
          if found.nil? and !index.nil?
            found = params[index] if params[index] && (params[index].name.nil? || params[index].name.empty?)
          end
          @return_type = ComplexType.parse(*found.types) unless found.nil? or found.types.nil?
        end
        super
        @return_type
      end

      # The parameter's zero-based location in the block's signature.
      #
      # @return [Integer]
      def index
        closure.parameter_names.index(name)
      end

      def try_merge! pin
        return false unless super
        # @todo This is a little expensive, but it's necessary because
        #   parameter data depends on the method's docstring.
        @return_type = pin.return_type
        reset_conversions
        true
      end
    end
  end
end
