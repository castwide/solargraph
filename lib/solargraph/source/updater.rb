module Solargraph
  class Source
    class Updater
      # @return [String]
      attr_reader :filename

      # @return [Integer]
      attr_reader :version

      # @return [Array<Change>]
      attr_reader :changes

      def initialize filename, version, changes
        @filename = filename
        @version = version
        @changes = changes
      end

      def write text
        changes.each do |ch|
          text = ch.write(text, changes.length == 1)
        end
        text
      end

      def repair text
        changes.each do |ch|
          text = ch.repair(text)
        end
        text
      end
    end
  end
end
