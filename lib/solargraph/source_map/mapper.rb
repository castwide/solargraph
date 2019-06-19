module Solargraph
  class SourceMap
    # The Mapper generates pins and other data for SourceMaps.
    #
    # This class is used internally by the SourceMap class. Users should not
    # normally need to call it directly.
    #
    class Mapper
      include Source::NodeMethods

      private_class_method :new

      MACRO_REGEXP = /(@\!method|@\!attribute|@\!domain|@\!macro|@\!parse)/.freeze

      # Generate the data.
      #
      # @param source [Source]
      # @return [Array]
      def map source
        @source = source
        @filename = source.filename
        @code = source.code
        @comments = source.comments
        @pins, @locals = NodeProcessor.process(source.node, Region.new(source: source))
        process_comment_directives
        [@pins, @locals]
      rescue Exception => e
        Solargraph.logger.warn "Error mapping #{source.filename}: [#{e.class}] #{e.message}"
        Solargraph.logger.warn e.backtrace.join("\n")
        [[], []]
      end

      # @param filename [String]
      # @param code [String]
      # @return [Array]
      def unmap filename, code
        s = Position.new(0, 0)
        e = Position.from_offset(code, code.length)
        location = Location.new(filename, Range.new(s, e))
        [[Pin::Namespace.new(location: location, name: '')], []]
      end

      class << self
        # @param source [Source]
        # @return [Array]
        def map source
          return new.unmap(source.filename, source.code) unless source.parsed?
          new.map source
        end
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      def closure_at(position)
        @pins.select{|pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position)}.last
      end

      def process_comment source_position, comment_position, comment
        return unless comment =~ MACRO_REGEXP
        cmnt = remove_inline_comment_hashes(comment)
        parse = Solargraph::Source.parse_docstring(cmnt)
        last_line = 0
        # @param d [YARD::Tags::Directive]
        parse.directives.each do |d|
          line_num = cmnt.lines[last_line..-1].find_index { |l| l.include?("@!#{d.tag.tag_name}") }
          line_num += last_line
          pos = Solargraph::Position.new(comment_position.line + line_num, comment_position.column)
          process_directive(source_position, pos, d)
          last_line = line_num + 1
        end
      end

      # @param position [Position]
      # @param directive [YARD::Tags::Directive]
      def process_directive source_position, comment_position, directive
        docstring = Solargraph::Source.parse_docstring(directive.tag.text).to_docstring
        location = Location.new(@filename, Range.new(comment_position, comment_position))
        case directive.tag.tag_name
        when 'method'
          namespace = closure_at(source_position)
          if namespace.location.range.start.line < comment_position.line
            namespace = closure_at(comment_position)
          end
          region = Region.new(source: @source, closure: namespace)
          src_node = Solargraph::Source.parse("def #{directive.tag.name};end", @filename, location.range.start.line)
          gen_pin = Solargraph::SourceMap::NodeProcessor.process(src_node, region).first.last
          return if gen_pin.nil?
          # @todo: Smelly instance variable access
          gen_pin.instance_variable_set(:@comments, docstring.all)
          @pins.push gen_pin
        when 'attribute'
          return if directive.tag.name.nil?
          namespace = closure_at(source_position)
          t = (directive.tag.types.nil? || directive.tag.types.empty?) ? nil : directive.tag.types.flatten.join('')
          if t.nil? || t.include?('r')
            pins.push Solargraph::Pin::Attribute.new(
              location: location,
              closure: namespace,
              name: directive.tag.name,
              comments: docstring.all,
              access: :reader,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public
            )
          end
          if t.nil? || t.include?('w')
            pins.push Solargraph::Pin::Attribute.new(
              location: location,
              closure: namespace,
              name: "#{directive.tag.name}=",
              comments: docstring.all,
              access: :writer,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public
            )
          end
        when 'parse'
          ns = closure_at(source_position)
          region = Region.new(source: @source, closure: ns)
          begin
            node = Solargraph::Source.parse(directive.tag.text, @filename, comment_position.line)
            NodeProcessor.process(node, region, @pins)
          rescue Parser::SyntaxError => e
            # @todo Handle parser errors in !parse directives
          end
        when 'domain'
          namespace = closure_at(source_position)
          namespace.domains.concat directive.tag.types unless directive.tag.types.nil?
        when 'override'
          pins.push Pin::Reference::Override.new(location, directive.tag.name, docstring.tags)
        end
      end

      def remove_inline_comment_hashes comment
        ctxt = ''
        num = nil
        started = false
        comment.lines.each { |l|
          # Trim the comment and minimum leading whitespace
          p = l.gsub(/^#/, '')
          if num.nil? && !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started && !p.strip.empty?
            cur = p.index(/[^ ]/)
            num = cur if cur < num
          end
          ctxt += "#{p[num..-1]}\n" if started
        }
        ctxt
      end

      # @return [void]
      def process_comment_directives
        return unless @code =~ MACRO_REGEXP
        used = []
        @source.associated_comments.each do |line, comments|
          used.concat comments
          src_pos = Position.new(line, @code.lines[line].chomp.length)
          com_pos = Position.new(comments.first.loc.line, comments.first.loc.column)
          txt = comments.map(&:text).join("\n")
          process_comment(src_pos, com_pos, txt)
        end
        left = @comments - used
        return if left.empty?
        txt = left.map(&:text).join("\n")
        com_pos = Position.new(left.first.loc.line, left.first.loc.column)
        process_comment(com_pos, com_pos, txt)
      end
    end
  end
end
