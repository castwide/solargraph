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
    @@logger = Logger.new(STDERR, level: level)
    # @sg-ignore Fix cvar issue
    @@logger.formatter = proc do |severity, _datetime, _progname, msg|
      "[#{severity}] #{msg}\n"
    end

    module_function

    # @return [Logger]
    def logger
      @@logger
    end
  end
end
