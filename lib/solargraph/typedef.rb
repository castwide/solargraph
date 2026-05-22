# frozen_string_literal: true

module Solargraph
  module Typedef
    autoload :Path,    'solargraph/typedef/path'
    autoload :Token,   'solargraph/typedef/token'
    autoload :Generic, 'solargraph/typedef/generic'
    autoload :Type,    'solargraph/typedef/type'

    # Convert a value to a Path or Token
    # @param value [String, Path, Token, Type]
    # @return [Path, Token, Type]
    def self.tokenize value
      case value
      when String
        convert value
      when Path, Token, Type
        value
      else
        raise 'Invalid'
      end
    end

    class << self
      private

      # @param string [String]
      # @return [Path, Token]
      def convert string
        case string
        when /^(::)?[A-Z][A-Za-z_(::)]*?/
          Path.new(string)
        when /^generic<[A-Za-z_]*>$/
          Token.new('generic', Token.new(string.scan(/<(.*?)>/)[0][0]))
        when /^[a-z]/i
          Token.new(string)
        else
          raise 'Invalid'
        end
      end
    end
  end
end
