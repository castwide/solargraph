# frozen_string_literal: true

require 'logger'

module Solargraph
  module Logging
    DEFAULT_LOG_LEVEL = Logger::WARN

    LOG_LEVELS = {
      'warn' => Logger::WARN,
      'info' => Logger::INFO,
      'debug' => Logger::DEBUG
    }
    configured_level = ENV.fetch('SOLARGRAPH_LOG', nil)
    level = if LOG_LEVELS.keys.include?(configured_level)
              LOG_LEVELS.fetch(configured_level)
            else
              if configured_level
                warn "Invalid value for SOLARGRAPH_LOG: #{configured_level.inspect} - " \
                     "valid values are #{LOG_LEVELS.keys}"
              end
              DEFAULT_LOG_LEVEL
            end
    # @sg-ignore Fix cvar issue
    @@logger = Logger.new(STDERR, level: level)
    # @sg-ignore Fix cvar issue
    @@logger.formatter = proc do |severity, datetime, progname, msg|
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
        logger = Logger.new(STDERR, level: new_log_level)
        logger.formatter = @@logger.formatter
        logger
      end
    end
  end
end
