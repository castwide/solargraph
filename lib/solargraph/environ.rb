module Solargraph
  class Environ
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<String>]
    attr_reader :domains

    # @param requires [Array<String>]
    # @param domains [Array<String>]
    def initialize requires: [], domains: []
      @requires = requires
      @domains = domains
    end

    # @return [self]
    def clear
      domains.clear
      requires.clear
      self
    end

    # @param other [Environ]
    # @return [self]
    def merge other
      domains.concat other.domains
      requires.concat other.requires
      self
    end
  end
end
