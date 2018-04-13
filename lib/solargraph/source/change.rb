module Solargraph
  class Source
    # A change to be applied to text.
    #
    class Change
      # @return [Range]
      attr_reader :range

      # @return [String]
      attr_reader :new_text

      # @param range [Range] The starting and ending positions of the change.
      #   If nil, the original text will be overwritten.
      # @param new_text [String] The text to be changed.
      def initialize range, new_text
        @range = range
        @new_text = new_text
      end

      # Write the change to the specified text.
      #
      # @param text [String] The text to be changed.
      # @param nullable [Boolean] If true, minor changes that could generate
      #   syntax errors will be repaired.
      # @return [String] The updated text.
      def write text, nullable = false
        if nullable and !range.nil? and new_text.match(/[\.\[\{\(@\$:]$/)
          commit text, "#{new_text[0..-2]} "
        elsif range.nil?
          new_text
        else
          commit text, new_text
        end
      end

      # Repair an update by replacing the new text with similarly formatted
      # whitespace.
      #
      # @param text [String] The text to be changed.
      # @return [String] The updated text.
      def repair text
        fixed = new_text.gsub(/[^\s]/, ' ')
        if range.nil?
          fixed
        else
          commit text, fixed
        end
      end

      private

      def commit text, insert
        start_offset = get_offset(text, range.start.line, range.start.character)
        end_offset = get_offset(text, range.ending.line, range.ending.character)
        (start_offset == 0 ? '' : text[0..start_offset-1].to_s) + insert.force_encoding('utf-8') + text[end_offset..-1].to_s
      end

      def get_offset text, line, column
        offset = 0
        feed = 0
        text.lines.each do |l|
          break if line == feed
          offset += l.length
          feed += 1
        end
        offset + column
      end
    end
  end
end
