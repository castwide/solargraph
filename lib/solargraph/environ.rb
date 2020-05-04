# frozen_string_literal: true

module Solargraph
  class Environ
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<String>]
    attr_reader :domains

    # @return [Array<Pin::Reference::Override>]
    attr_reader :pins

    # @param requires [Array<String>]
    # @param domains [Array<String>]
    # @param overrides [Array<Pin::Reference::Override>]
    def initialize requires: [], domains: [], pins: []
      @requires = requires
      @domains = domains
      @pins = pins
    end

    # @return [self]
    def clear
      domains.clear
      requires.clear
      pins.clear
      self
    end

    # @param other [Environ]
    # @return [self]
    def merge other
      domains.concat other.domains
      requires.concat other.requires
      pins.concat other.pins
      self
    end
  end
end
