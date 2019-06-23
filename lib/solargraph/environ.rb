module Solargraph
  class Environ
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<String>]
    attr_reader :domains

    # @return [Array<Pin::Reference::Override>]
    attr_reader :overrides

    # @param requires [Array<String>]
    # @param domains [Array<String>]
    # @param overrides [Array<Pin::Reference::Override>]
    def initialize requires: [], domains: [], overrides: []
      @requires = requires
      @domains = domains
      @overrides = overrides
    end

    # @return [self]
    def clear
      domains.clear
      requires.clear
      overrides.clear
      self
    end

    # @param other [Environ]
    # @return [self]
    def merge other
      domains.concat other.domains
      requires.concat other.requires
      overrides.concat other.overrides
      self
    end
  end
end
