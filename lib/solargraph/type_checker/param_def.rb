module Solargraph
  class TypeChecker
    # Data about a method parameter definition. This is the information from
    # the args list in the def call, not the `@param` tags.
    #
    class ParamDef
      # @return [String]
      attr_reader :name

      # @return [Symbol]
      attr_reader :type

      def initialize name, type
        @name = name
        @type = type
      end

      class << self
        # Get an array of ParamDefs from a method pin.
        #
        # @param pin [Solargraph::Pin::BaseMethod]
        # @return [Array<ParamDef>]
        def from pin
          result = []
          pin.parameters.each_with_index do |full, index|
            result.push ParamDef.new(pin.parameter_names[index], arg_type(full))
          end
          result
        end

        private

        # @param string [String]
        # @return [Symbol]
        def arg_type string
          return :kwrestarg if string.start_with?('**')
          return :restarg if string.start_with?('*')
          return :optarg if string.include?('=')
          return :kwoptarg if string.end_with?(':')
          return :kwarg if string =~ /^[a-z0-9_]*?:/
          :arg
        end
      end

    end
  end
end
