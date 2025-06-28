# frozen_string_literal: true

require 'prism'

# Awaiting ability to use a version containing https://github.com/whitequark/parser/pull/1076
#
# @!parse
#   class ::Parser::Base < ::Parser::Builder
#     # @return [Integer]
#     def version; end
#   end
#   class ::Parser::CurrentRuby < ::Parser::Base; end

module Solargraph
  module Parser
    module ParserGem
      module ClassMethods
        # @param code [String]
        # @param filename [String, nil]
        # @return [Array(Parser::AST::Node, Hash{Integer => String})]
        def parse_with_comments code, filename = nil
          node = parse(code, filename)
          comments = CommentRipper.new(code, filename, 0).parse
          [node, comments]
        end

        # @param code [String]
        # @param filename [String, nil]
        # @param line [Integer]
        # @return [Parser::AST::Node]
        def parse code, filename = nil, line = 0
          buffer = ::Parser::Source::Buffer.new(filename, line)
          buffer.source = code
          parser.parse(buffer)
        rescue ::Parser::SyntaxError, ::Parser::UnknownEncodingInMagicComment => e
          raise Parser::SyntaxError, e.message
        end

        # @return [::Parser::Base]
        def parser
          @parser ||= Prism::Translation::Parser.new(FlawedBuilder.new).tap do |parser|
            parser.diagnostics.all_errors_are_fatal = true
            parser.diagnostics.ignore_warnings      = true
          end
        end

        # @param source [Source]
        # @return [Array(Array<Pin::Base>, Array<Pin::Base>)]
        def map source
          NodeProcessor.process(source.node, Region.new(source: source))
        end

        # @param source [Source]
        # @param name [String]
        # @return [Array<Location>]
        def references source, name
          if name.end_with?("=")
            reg = /#{Regexp.escape name[0..-2]}\s*=/
            # @param code [String]
            # @param offset [Integer]
            # @return [Array(Integer, Integer), Array(nil, nil)]
            extract_offset = ->(code, offset) { reg.match(code, offset).offset(0) }
          else
            # @param code [String]
            # @param offset [Integer]
            # @return [Array(Integer, Integer), Array(nil, nil)]
            extract_offset = ->(code, offset) { [soff = code.index(name, offset), soff + name.length] }
          end
          inner_node_references(name, source.node).map do |n|
            rng = Range.from_node(n)
            offset = Position.to_offset(source.code, rng.start)
            soff, eoff = extract_offset[source.code, offset]
            Location.new(
              source.filename,
              Range.new(
                Position.from_offset(source.code, soff),
                Position.from_offset(source.code, eoff)
              )
            )
          end
        end

        # @param name [String]
        # @param top [AST::Node]
        # @return [Array<AST::Node>]
        def inner_node_references name, top
          result = []
          if top.is_a?(AST::Node) && top.to_s.include?(":#{name}")
            result.push top if top.children.any? { |c| c.to_s == name }
            top.children.each { |c| result.concat inner_node_references(name, c) }
          end
          result
        end

        # @return [Source::Chain]
        def chain *args
          NodeChainer.chain *args
        end

        # @return [Source::Chain]
        def chain_string *args
          NodeChainer.load_string *args
        end

        # @return [Array(Array<Pin::Base>, Array<Pin::Base>)]
        def process_node *args
          Solargraph::Parser::NodeProcessor.process *args
        end

        # @param node [Parser::AST::Node]
        # @return [String, nil]
        def infer_literal_node_type node
          NodeMethods.infer_literal_node_type node
        end

        # @return [Integer]
        def version
          parser.version
        end

        # @param node [BasicObject]
        # @return [Boolean]
        def is_ast_node? node
          node.is_a?(::Parser::AST::Node)
        end

        # @param node [Parser::AST::Node]
        # @return [Range]
        def node_range node
          st = Position.new(node.loc.line, node.loc.column)
          en = Position.new(node.loc.last_line, node.loc.last_column)
          Range.new(st, en)
        end

        # @param node [Parser::AST::Node]
        # @return [Array<Range>]
        def string_ranges node
          return [] unless is_ast_node?(node)
          result = []
          if node.type == :str
            result.push Range.from_node(node)
          end
          node.children.each do |child|
            result.concat string_ranges(child)
          end
          if node.type == :dstr && node.children.last.nil?
            last = node.children[-2]
            unless last.nil?
              rng = Range.from_node(last)
              pos = Position.new(rng.ending.line, rng.ending.column - 1)
              result.push Range.new(pos, pos)
            end
          end
          result
        end
      end
    end
  end
end
