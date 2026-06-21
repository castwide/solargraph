# frozen_string_literal: true

module Solargraph
  module Typedef
    autoload :Path,       'solargraph/typedef/path'
    autoload :Token,      'solargraph/typedef/token'
    autoload :Type,       'solargraph/typedef/type'
    autoload :Linker,     'solargraph/typedef/linker'
    autoload :Memos,      'solargraph/typedef/memos'
    autoload :Dictionary, 'solargraph/typedef/dictionary'
    autoload :Expansions, 'solargraph/typedef/expansions'
    autoload :Typeset,    'solargraph/typedef/typeset'
    autoload :Tuple,      'solargraph/typedef/tuple'

    # Convert a value to a Path or Token
    # @param value [String, Path, Token, Type, Array<String, Path, Token, Type>]
    # @return [Path, Token, Type]
    def self.tokenize value
      case value
      when String
        convert value
      when Path, Token, Type, Typeset, Tuple
        value
      when Array
        Typedef::Type.new(*value)
      else
        raise "Invalid value #{value.inspect}"
      end
    end

    def self.memos
      @memos ||= Memos.new
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
        when /^?[a-z\d_]*?$/
          Token.new(string)
        when /^"?[a-z\d_]*?"$/
          Token.new(string)
        when /^\:?[a-z\d_]*?$/
          Token.new(string)
        # @todo How to handle integers?
        when /^\d+$/
          Token.new(string)
        else
          raise "Invalid Typedef token string: #{string.inspect}"
        end
      end
    end
  end
end
