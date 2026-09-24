# frozen_string_literal: true

require 'logger'

module Solargraph
  module Logging
    # @type [Integer]
    DEFAULT_LOG_LEVEL = Logger::WARN

    # @type [Hash{String => Integer}]
    LOG_LEVELS = {
      'warn' => Logger::WARN,
      'info' => Logger::INFO,
      'debug' => Logger::DEBUG
    }.freeze
    # @param configured_level [String, nil]
    # @return [Integer]
    # @sg-ignore https://github.com/apiology/solargraph/pull/65
    # @sg-ignore https://github.com/castwide/solargraph/pull/1223
    def self.resolve_level configured_level = ENV.fetch('SOLARGRAPH_LOG', nil)
      return LOG_LEVELS.fetch(configured_level) if LOG_LEVELS.key?(configured_level)

      if configured_level
        $stderr.puts "Invalid value for SOLARGRAPH_LOG: #{configured_level.inspect} - " \
                     "valid values are #{LOG_LEVELS.keys}"
      end
      DEFAULT_LOG_LEVEL
    end

    @@logger = Logger.new($stderr, level: resolve_level)
    # @sg-ignore Fix cvar issue
    @@logger.formatter = proc do |severity, _datetime, _progname, msg|
      "[#{severity}] #{msg}\n"
    end

    module_function

    # override this in your class to temporarily set a custom
    # filtering log level for the class (e.g., suppress any debug
    # message by setting it to :info even if it is set elsewhere, or
    # show existing debug messages by setting to :debug).
    #
    # @return [Symbol]
    def log_level
      :warn
    end

    # @return [Logger]
    def logger
      if LOG_LEVELS[log_level.to_s] == DEFAULT_LOG_LEVEL
        @@logger
      else
        new_log_level = LOG_LEVELS[log_level.to_s]
        logger = Logger.new($stderr, level: new_log_level)

        logger.formatter = @@logger.formatter
        logger
      end
    end
  end
end
