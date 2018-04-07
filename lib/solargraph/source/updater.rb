module Solargraph
  class Source
    # Updaters contain changes to be applied to a source. The source applies
    # the update via the Source#synchronize method.
    #
    class Updater
      # @return [String]
      attr_reader :filename

      # @return [Integer]
      attr_reader :version

      # @return [Array<Change>]
      attr_reader :changes

      # @param filename [String] The file to update.
      # @param version [Integer] A version number associated with this update.
      # @param changes [Array<Solargraph::Source::Change>] The changes.
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
