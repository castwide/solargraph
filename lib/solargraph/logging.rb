require 'logger'

module Solargraph
  module Logging
    DEFAULT_LOG_LEVEL = Logger::WARN

    module_function

    def logger
      @@logger ||= Logger.new(STDERR, level: DEFAULT_LOG_LEVEL)
    end
  end
end
