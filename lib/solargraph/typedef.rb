# frozen_string_literal: true

module Solargraph
  module Typedef
    autoload :Path,       'solargraph/typedef/path'
    autoload :Token,      'solargraph/typedef/token'
    autoload :Concrete,    'solargraph/typedef/concrete'
    autoload :Linker,     'solargraph/typedef/linker'
    autoload :Memoizer,   'solargraph/typedef/memoizer'
    autoload :Dictionary, 'solargraph/typedef/dictionary'
    autoload :Expansions, 'solargraph/typedef/expansions'
    autoload :Typeset,    'solargraph/typedef/typeset'
    autoload :Union,      'solargraph/typedef/union'
    autoload :Tuple,      'solargraph/typedef/tuple'

    # Convert a value to a Path, Token, or Type
    # @param value [String, Path, Token, Type, Array<String, Path, Token, Type>]
    # @return [Path, Token, Type]
    def self.tokenize value
      case value
      when String
        convert value
      when Path, Token, Type
        value
      when Array
        Typedef::Concrete.new(*value)
      else
        raise "Invalid value #{value.inspect}"
      end
    end

    def self.memos
      @memos ||= Memoizer::Cache.new
    end

    class << self
      private

      # @param string [String]
      # @return [Path, Token]
      def convert string
        # @todo cleanup
        # rubocop:disable Lint\DuplicateBranch
        case string
        when 's'
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
        when /^:?[a-z\d_]*?$/
          Token.new(string)
        # @todo How to handle integers?
        when /^\d+$/
          Token.new(string)
        else
          raise "Invalid Typedef token string: #{string.inspect}"
        end
        # rubocop:enable Lint\DuplicateBranch
      end
    end
  end
end
