# frozen_string_literal: true

module Solargraph
  class SourceMap
    # The Mapper generates pins and other data for SourceMaps.
    #
    # This class is used internally by the SourceMap class. Users should not
    # normally need to call it directly.
    #
    class Mapper
      # include Source::NodeMethods

      private_class_method :new

      DIRECTIVE_REGEXP = /(@!method|@!attribute|@!visibility|@!domain|@!macro|@!parse|@!override)/

      # Generate the data.
      #
      # @param source [Source]
      # @return [Array]
      def map source
        @source = source
        @filename = source.filename
        @code = source.code
        @comments = source.comments
        @pins, @locals = Parser.map(source)
        # @param p [Solargraph::Pin::Base]
        @pins.each { |p| p.source = :code }
        @locals.each { |l| l.source = :code }
        process_comment_directives
        [@pins, @locals]
        # rescue Exception => e
        #   Solargraph.logger.warn "Error mapping #{source.filename}: [#{e.class}] #{e.message}"
        #   Solargraph.logger.warn e.backtrace.join("\n")
        #   [[], []]
      end

      # @param filename [String]
      # @param code [String]
      # @return [Array]
      def unmap filename, code
        s = Position.new(0, 0)
        e = Position.from_offset(code, code.length)
        location = Location.new(filename, Range.new(s, e))
        [[Pin::Namespace.new(location: location, name: '', source: :source_map)], []]
      end

      class << self
        # @param source [Source]
        # @return [Array]
        def map source
          # @sg-ignore Need to add nil check here
          return new.unmap(source.filename, source.code) unless source.parsed?
          new.map source
        end
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        # @type [Array<Solargraph::Pin::Base>]
        @pins ||= []
      end

      # @param source_position [Position]
      # @param comment_position [Position]
      # @param comment [String]
      # @return [void]
      def process_comment source_position, comment_position, comment
        return unless comment.encode('UTF-8', invalid: :replace, replace: '?') =~ DIRECTIVE_REGEXP
        cmnt = remove_inline_comment_hashes(comment)
        parse = Solargraph::Source.parse_docstring(cmnt)
        last_line = 0
        # @param d [YARD::Tags::Directive]
        parse.directives.each do |d|
          line_num = find_directive_line_number(cmnt, d.tag.tag_name, last_line)
          pos = Solargraph::Position.new(comment_position.line + line_num - 1, comment_position.column)
          process_directive(source_position, pos, d)
          last_line = line_num + 1
        end
      end

      # @param comment [String]
      # @param tag [String]
      # @param start [Integer]
      # @return [Integer]
      def find_directive_line_number comment, tag, start
        # Avoid overruning the index
        return start unless start < comment.lines.length
        # @sg-ignore Need to add nil check here
        num = comment.lines[start..].find_index do |line|
          # Legacy method directives might be `@method` instead of `@!method`
          # @todo Legacy syntax should probably emit a warning
          line.include?("@!#{tag}") || (tag == 'method' && line.include?("@#{tag}"))
        end
        # @sg-ignore Need to add nil check here
        num.to_i + start
      end

      # @param source_position [Position]
      # @param comment_position [Position]
      # @param directive [YARD::Tags::Directive]
      # @return [void]
      def process_directive source_position, comment_position, directive
        directive_processor = YardMap::Directives.for(directive)
        return unless directive_processor

        @pins += directive_processor.process_directive(
          @source, @pins, source_position, comment_position, directive
        )
      end

      # @param comment [String]
      # @return [String]
      def remove_inline_comment_hashes comment
        ctxt = ''
        num = nil
        started = false
        comment.lines.each do |l|
          # Trim the comment and minimum leading whitespace
          p = l.encode('UTF-8', invalid: :replace, replace: '?').gsub(/^#+/, '')
          if num.nil? && !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started && !p.strip.empty?
            cur = p.index(/[^ ]/)
            # @sg-ignore Need to add nil check here
            num = cur if cur < num
          end
          ctxt += p[num..].to_s if started
        end
        ctxt
      end

      # @return [void]
      def process_comment_directives
        return unless @code.encode('UTF-8', invalid: :replace, replace: '?') =~ DIRECTIVE_REGEXP
        code_lines = @code.lines
        @source.associated_comments.each do |line, comments|
          src_pos = if line
                      Position.new(line,
                                   code_lines[line].to_s.chomp.index(/[^\s]/) || 0)
                    else
                      Position.new(
                        code_lines.length, 0
                      )
                    end
          # @sg-ignore Need to add nil check here
          com_pos = Position.new(line + 1 - comments.lines.length, 0)
          process_comment(src_pos, com_pos, comments)
        end
      rescue StandardError => e
        raise e.class, "Error processing comment directives in #{@filename}: #{e.message}"
      end
    end
  end
end
