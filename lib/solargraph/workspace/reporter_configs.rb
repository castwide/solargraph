require 'yaml'

module Solargraph
  class Workspace
    # Configuration data for a collection of reporters.
    #
    class ReporterConfigs
      include Enumerable

      # @param reporter_config [Array<String, Object>]
      def initialize(reporter_config)
        @reporter_config = reporter_config
      end

      # Enumerable method to allow iteration of values.
      #
      # @param &_block The block that processes the response
      # @yieldparam [String] The string name of the reporter
      # @yieldparam [Hash] The reporter configuration
      # @return [Array<String, Hash>, Enumerator] Collection of reporters and their configs
      def each(&_block)
        return @reporter_config.each unless block_given?

        @reporter_config.each do |reporter|
          next yield(reporter, {}) if reporter.is_a?(String)
          yield(reporter.keys.first, reporter.values.first)
        end
      end
    end
  end
end
