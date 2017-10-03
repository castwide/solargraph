require 'parser/current'

module Solargraph
  class ApiMap
    class Source
      attr_reader :code
      attr_reader :node
      attr_reader :comments
      attr_reader :filename

      def initialize code, node, comments, filename
        @code = code
        root = AST::Node.new(:begin, [filename])
        root = root.append node
        @node = root
        @comments = comments
        @docstring_hash = associate_comments(node, comments)
        @filename = filename
      end

      def docstring_for node
        @docstring_hash[node.loc]
      end

      def code_for node
        b = node.location.expression.begin.begin_pos
        e = node.location.expression.end.end_pos
        frag = code[b..e].to_s
        frag.strip.gsub(/,$/, '')
      end

      private

      def associate_comments node, comments
        comment_hash = Parser::Source::Comment.associate_locations(node, comments)
        yard_hash = {}
        comment_hash.each_pair { |k, v|
          ctxt = ''
          num = nil
          started = false
          v.each { |l|
            # Trim the comment and minimum leading whitespace
            p = l.text.gsub(/^#/, '')
            if num.nil? and !p.strip.empty?
              num = p.index(/[^ ]/)
              started = true
            elsif started and !p.strip.empty?
              cur = p.index(/[^ ]/)
              num = cur if cur < num
            end
            if started
              ctxt += "#{p[num..-1]}\n"
            end
          }
          yard_hash[k] = YARD::Docstring.parser.parse(ctxt).to_docstring
        }
        yard_hash
      end
  
      class << self
        # @return [Solargraph::ApiMap::Source]
        def load filename
          code = File.read(filename).gsub(/\r/, '')
          node, comments = Parser::CurrentRuby.parse_with_comments(code)
          Source.new(code, node, comments, filename)
        end

        def fix filename, code, cursor = nil
          tries = 0
          code.gsub!(/\r/, '')
          tmp = code
          cursor = CodeMap.get_offset(code, cursor[0], cursor[1]) if cursor.kind_of?(Array)
          fixed_cursor = false
          begin
            # HACK: The current file is parsed with a trailing underscore to fix
            # incomplete trees resulting from short scripts (e.g., a lone variable
            # assignment).
            node, comments = Parser::CurrentRuby.parse_with_comments(tmp + "\n_")
            #@node = self.api_map.append_node(node, @comments, filename)
            #@parsed = tmp
            #@code.freeze
            #@parsed.freeze
            Source.new(code, node, comments, filename)
          rescue Parser::SyntaxError => e
            if tries < 10
              tries += 1
              if tries == 10 and e.message.include?('token $end')
                tmp += "\nend"
              else
                if !fixed_cursor and !cursor.nil? and e.message.include?('token $end') and cursor >= 2
                  fixed_cursor = true
                  spot = cursor - 2
                  if tmp[cursor - 1] == '.'
                    repl = ';'
                  else
                    repl = '#'
                  end
                else
                  spot = e.diagnostic.location.begin_pos
                  repl = '_'
                  if tmp[spot] == '@' or tmp[spot] == ':'
                    # Stub unfinished instance variables and symbols
                    spot -= 1
                  elsif tmp[spot - 1] == '.'
                    # Stub unfinished method calls
                    repl = '#' if spot == tmp.length or tmp[spot] == '\n'
                    spot -= 2
                  else
                    # Stub the whole line
                    spot = beginning_of_line_from(tmp, spot)
                    repl = '#'
                    if tmp[spot+1..-1].rstrip == 'end'
                      repl= 'end;end'
                    end
                  end
                end
                tmp = tmp[0..spot] + repl + tmp[spot+repl.length+1..-1].to_s
              end
              retry
            end
            raise e
          end
        end

        def beginning_of_line_from str, i
          while i > 0 and str[i] != "\n"
            i -= 1
          end
          if i > 0 and str[i..-1].strip == ''
            i = beginning_of_line_from str, i -1
          end
          i
        end    
      end
    end
  end
end
