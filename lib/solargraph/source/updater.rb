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
        @input = nil
        @did_nullify = nil
        @output = nil
      end

      # @return [String]
      def write text, nullable = false
        can_nullify = (nullable and changes.length == 1)
        return @output if @input == text and can_nullify == @did_nullify
        @input = text
        @output = text
        @did_nullify = can_nullify
        changes.each do |ch|
          @output = ch.write(@output, can_nullify)
        end
        @output
      end

      # @return [String]
      def repair text
        changes.each do |ch|
          text = ch.repair(text)
        end
        text
      end

      # This is an insane hack to fix a discrepancy in version numbers and
      # content changes. It's far from perfect.
      #
      # @return [Integer]
      def effective_changes
        # changes.length
        @effective_changes ||= begin
          result = 0
          last_change = nil
          changes.each do |change|
            if last_change.nil?
              result += 1
              last_change = change
            else
              if change.range.nil?
                result += 1
                last_change = nil
              else
                if last_change.range.start == last_change.range.ending and last_change.range.ending == change.range.ending and change.new_text.empty?
                  # Some kind of modification to the previous change
                elsif change.range.start == change.range.ending and last_change.range.start == change.range.start and last_change.new_text.empty?
                  # Same idea reversed
                elsif change.range.start.line == change.range.ending.line and last_change.range.start.line == change.range.start.line - 1 and last_change.range.ending.line == change.range.ending.line - 1 and last_change.range.start.column == 0 and change.range.start.column == 0 and last_change.new_text == change.new_text
                  # A block of identical changes
                elsif change.range.start.line == change.range.ending.line and last_change.range.start.line == change.range.start.line + 1 and last_change.range.ending.line == change.range.ending.line + 1 and last_change.range.start.column == 0 and change.range.start.column == 0 and last_change.new_text == change.new_text
                  # Same idea reversed
                else
                  result += 1
                end
                last_change = change
              end
            end
          end
          result
        end
      end
    end
  end
end
