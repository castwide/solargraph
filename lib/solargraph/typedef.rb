# frozen_string_literal: true

module Solargraph
  module Typedef
    autoload :Path,       'solargraph/typedef/path'
    autoload :Token,      'solargraph/typedef/token'
    autoload :Type,       'solargraph/typedef/type'
    autoload :Linker,     'solargraph/typedef/linker'
    autoload :Dictionary, 'solargraph/typedef/dictionary'

    # Convert a value to a Path or Token
    # @param value [String, Path, Token, Type, Array<String, Path, Token, Type>]
    # @return [Path, Token, Type]
    def self.tokenize value
      case value
      when String
        convert value
      when Path, Token, Type
        value
      when Array
        Typedef::Type.new(*value)
      else
        raise "Invalid value #{value.inspect}"
      end
    end

    class << self
      private

      # @param string [String]
      # @return [Path, Token]
      def convert string
        case string
        when ""
          Path::ROOT
        # @todo Should interfaces (e.g, `_Each`) be paths?
        #   (Probably)
        when /^(::)?[A-Z_][A-Za-z_(::)]*?/
          Path.new(string)
        when /^generic<[A-Za-z\d_]*>$/
          Token.new(string)
        when /^[a-z]*$/
          Token.new(string)
        # @todo How to handle integers?
        when /\d+/
          Token.new(string)
        else
          raise "Invalid string: #{string}"
        end
      end
    end
  end
end
