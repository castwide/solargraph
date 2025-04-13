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
    configured_level = ENV['SOLARGRAPH_LOG']
    level = if LOG_LEVELS.keys.include?(configured_level)
              LOG_LEVELS.fetch(configured_level)
            else
              STDERR.puts("Invalid value for SOLARGRAPH_LOG: #{configured_level.inspect} - valid values are #{LOG_LEVELS.keys}") if configured_level
              DEFAULT_LOG_LEVEL
            end
    @@logger = Logger.new(STDERR, level: level)
    @@logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{severity}] #{msg}\n"
    end

    module_function

    # @return [Logger]
    def logger
      @@logger
    end
  end
end
