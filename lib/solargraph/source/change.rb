module Solargraph
  class Source
    class Change
      # @return [Range]
      attr_reader :range

      # @return [String]
      attr_reader :new_text

      # @param range [Range]
      # @param new_text [String]
      def initialize range, new_text
        @range = range
        @new_text = new_text
      end

      def write text, nullable = false
        if nullable and new_text.match(/\.\[\{\(\s?$/i)
          commit "#{new_text[0..-2]} "
        elsif range.nil?
          new_text
        else
          commit text, new_text
        end
      end

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
        end_offset = get_offset(text, range.end.line, range.end.character)
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
