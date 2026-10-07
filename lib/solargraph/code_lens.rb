# frozen_string_literal: true

module Solargraph
  # A command shown inline in the source, e.g. "Run" above an RSpec example.
  # Conventions provide code lenses through their Environs.
  #
  class CodeLens
    # @return [Range]
    attr_reader :range

    # @return [Command]
    attr_reader :command

    # @param range [Range]
    # @param command [Command]
    def initialize range:, command:
      @range = range
      @command = command
    end

    # @return [Hash]
    def to_hash
      {
        range: range.to_hash,
        command: command.to_hash
      }
    end
  end
end
