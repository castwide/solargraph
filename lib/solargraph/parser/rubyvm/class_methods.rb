require 'solargraph/parser/rubyvm/node_processors'

module Solargraph
  module Parser
    module Rubyvm
      module ClassMethods
        # @param code [String]
        # @param filename [String]
        # @return [Array(Parser::AST::Node, Array<Parser::Source::Comment>)]
        def parse_with_comments code, filename = nil
          node = RubyVM::AbstractSyntaxTree.parse(code)
          comments = CommentRipper.new(code).parse
          [node, comments]
        rescue ::SyntaxError => e
          raise Parser::SyntaxError, e.message
        end

        # @param code [String]
        # @param filename [String, nil]
        # @param line [Integer]
        # @return [Parser::AST::Node]
        def parse code, filename = nil, line = 0
          RubyVM::AbstractSyntaxTree.parse(code)
        rescue ::SyntaxError => e
          raise Parser::SyntaxError, e.message
        end

        def map source
          NodeProcessor.process(source.node, Region.new(source: source))
        end

        # def returns_from node
        #   return [] unless Parser.is_ast_node?(node)
        #   if node.type == :SCOPE
        #     # node.children.select { |n| n.is_a?(RubyVM::AbstractSyntaxTree::Node) }.map { |n| DeepInference.get_return_nodes(n) }.flatten
        #     DeepInference.get_return_nodes(node.children[2])
        #   else
        #     DeepInference.get_return_nodes(node)
        #   end
        # end

        def references source, name
          inner_node_references(name, source.node).map do |n|
            rng = Range.from_node(n)
            offset = Position.to_offset(source.code, rng.start)
            soff = source.code.index(name, offset)
            eoff = soff + name.length
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
          if Parser.rubyvm?
            if Parser.is_ast_node?(top)
              result.push top if match_rubyvm_node_to_ref(top, name)
              top.children.each { |c| result.concat inner_node_references(name, c) }
            end
          else
            if Parser.is_ast_node?(top) && top.to_s.include?(":#{name}")
              result.push top if top.children.any? { |c| c.to_s == name }
              top.children.each { |c| result.concat inner_node_references(name, c) }
            end
          end
          result
        end

        def match_rubyvm_node_to_ref(top, name)
          top.children.select { |c| c.is_a?(Symbol) }.any? { |c| c.to_s == name } ||
            top.children.select { |c| c.is_a?(Array) }.any? { |c| c.include?(name.to_sym) }
        end

        def chain *args
          NodeChainer.chain *args
        end

        def process_node *args
          Solargraph::Parser::NodeProcessor.process *args
        end

        def infer_literal_node_type node
          # NodeMethods.infer_literal_node_type node
        end

        def version
          Ruby::VERSION
        end

        def is_ast_node? node
          if Parser.rubyvm?
            node.is_a?(RubyVM::AbstractSyntaxTree::Node)
          else
            node.is_a?(::Parser::AST::Node)
          end
        end

        def node_range node
          st = Position.new(node.first_lineno - 1, node.first_column)
          en = Position.new(node.last_lineno - 1, node.last_column)
          Range.new(st, en)
        end

        def recipient_node tree
          tree.each_with_index do |node, idx|
            return tree[idx + 1] if [:ARRAY, :ZARRAY, :LIST].include?(node.type) && tree[idx + 1] && [:FCALL, :VCALL, :CALL].include?(tree[idx + 1].type)
          end
          nil
        end

        def string_ranges node
          return [] unless is_ast_node?(node)
          result = []
          if node.type == :STR
            result.push Range.from_node(node)
          elsif node.type == :DSTR
            here = Range.from_node(node)
            there = Range.from_node(node.children[1])
            result.push Range.new(here.start, there.start)
          end
          node.children.each do |child|
            result.concat string_ranges(child)
          end
          if node.type == :DSTR && node.children.last.nil?
            # result.push Range.new(result.last.ending, result.last.ending)
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
