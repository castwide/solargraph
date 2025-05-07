# frozen_string_literal: true

module Solargraph
  # @abstract This mixin relies on these -
  #   methods:
  #     equality_fields()
  module Equality
    # @!method equality_fields
    #   @return [Array]

    # @param other [Object]
    # @return [Boolean]
    def eql?(other)
      self.class.eql?(other.class) &&
        equality_fields.eql?(other.equality_fields)
    end

    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      self.eql?(other)
    end

    def hash
      equality_fields.hash
    end

    def freeze
      equality_fields.each(&:freeze)
      super
    end
  end
end
