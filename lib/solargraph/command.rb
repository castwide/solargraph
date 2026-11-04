# frozen_string_literal: true

module Solargraph
  # An LSP command the client can execute, e.g. from a code lens or a code
  # action.
  #
  class Command
    # @return [String]
    attr_reader :title

    # @return [String] The identifier of a command registered by the client
    attr_reader :command

    # @return [Array]
    attr_reader :arguments

    # @param title [String]
    # @param command [String]
    # @param arguments [Array]
    def initialize title:, command:, arguments: []
      @title = title
      @command = command
      @arguments = arguments
    end

    # @return [Hash]
    def to_hash
      {
        title: title,
        command: command,
        arguments: arguments
      }
    end
  end
end
