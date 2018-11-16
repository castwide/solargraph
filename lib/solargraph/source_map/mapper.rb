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

      # Generate the data.
      #
      # @return [Array]
      def map source
        @filename = source.filename
        @code = source.code
        @comments = source.comments
        @pins = Solargraph::SourceMap::NodeProcessor.process(source.node, Solargraph::SourceMap::Region.new(source: source), [])
        process_comment_directives
        locals = @pins.select{|p| [Pin::LocalVariable, Pin::MethodParameter, Pin::BlockParameter].include?(p.class)}
        [@pins - locals, locals]
      end

      def unmap filename, code
        s = Position.new(0, 0)
        e = Position.from_offset(code, code.length)
        location = Location.new(filename, Range.new(s, e))
        [[Pin::Namespace.new(location, '', '', '', :class, :public)], []]
      end

      class << self
        # @param source [Source]
        # @return [Array]
        def map source
          return new.unmap(source.filename, source.code) unless source.parsed?
          new.map source
        end
      end

      # @return [String]
      def filename
        @filename
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      # @param node [Parser::AST::Node]
      # @return [Solargraph::Pin::Namespace]
      def namespace_for(node)
        position = Position.new(node.loc.line, node.loc.column)
        namespace_at(position)
      end

      def namespace_at(position)
        @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.location.range.contain?(position)}.last
      end

      def process_comment position, comment
        cmnt = remove_inline_comment_hashes(comment)
        return unless cmnt =~ /(@\!method|@\!attribute|@\!domain|@\!macro|@\!parse)/
        parse = YARD::Docstring.parser.parse(cmnt)
        parse.directives.each { |d| process_directive(position, d) }
      end

      # @param position [Position]
      # @param directive [YARD::Tags::Directive]
      def process_directive position, directive
        docstring = YARD::Docstring.parser.parse(directive.tag.text).to_docstring
        location = Location.new(@filename, Range.new(position, position))
        case directive.tag.tag_name
        when 'method'
          namespace = namespace_at(position)
          gen_src = Solargraph::SourceMap.load_string("def #{directive.tag.name};end")
          gen_pin = gen_src.pins.last # Method is last pin after root namespace
          @pins.push Solargraph::Pin::Method.new(location, namespace.path, gen_pin.name, docstring.all, :instance, :public, gen_pin.parameters, nil)
        when 'attribute'
          namespace = namespace_at(position)
          t = (directive.tag.types.nil? || directive.tag.types.empty?) ? nil : directive.tag.types.flatten.join('')
          if t.nil? || t.include?('r')
            # location, namespace, name, docstring, access
            pins.push Solargraph::Pin::Attribute.new(location, namespace.path, directive.tag.name, docstring.all, :reader, :instance, :public)
          end
          if t.nil? || t.include?('w')
            pins.push Solargraph::Pin::Attribute.new(location, namespace.path, "#{directive.tag.name}=", docstring.all, :writer, :instance, :public)
          end
        when 'parse'
          # @todo Parse and map directive.tag.text
        when 'domain'
          namespace = namespace_at(position)
          namespace.domains.push directive.tag.text
        end
      end

      def remove_inline_comment_hashes comment
        ctxt = ''
        num = nil
        started = false
        comment.lines.each { |l|
          # Trim the comment and minimum leading whitespace
          p = l.gsub(/^#/, '')
          if num.nil? and !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started and !p.strip.empty?
            cur = p.index(/[^ ]/)
            num = cur if cur < num
          end
          ctxt += "#{p[num..-1]}\n" if started
        }
        ctxt
      end

      def process_comment_directives
        current = []
        last_line = nil
        @comments.each do |cmnt|
          if cmnt.inline?
            if last_line.nil? || cmnt.loc.expression.line == last_line + 1
              if cmnt.loc.expression.column.zero? || @code.lines[cmnt.loc.expression.line][0..cmnt.loc.expression.column-1].strip.empty?
                current.push cmnt
              else
                # @todo Connected to a line of code. Handle separately
              end
            elsif !current.empty?
              process_comment Position.new(current.last.loc.expression.line, current.last.loc.expression.column), current.map(&:text).join("\n")
              current.clear
              current.push cmnt
            end
          else
            # @todo Handle block comments
          end
          last_line = cmnt.loc.expression.line
        end
        unless current.empty?
          process_comment Position.new(current.last.loc.expression.line, current.last.loc.expression.column), current.map(&:text).join("\n")
        end
      end
    end
  end
end
