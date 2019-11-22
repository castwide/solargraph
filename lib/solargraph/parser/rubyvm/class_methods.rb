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
        end

        def map source
          NodeProcessor.process(source.node, Region.new(source: source))
        end

        def returns_from node
          # NodeMethods.returns_from(node)
        end

        def references source, name
          # inner_node_references(name, source.node).map do |n|
          #   offset = Position.to_offset(source.code, NodeMethods.get_node_start_position(n))
          #   soff = source.code.index(name, offset)
          #   eoff = soff + name.length
          #   Location.new(
          #     source.filename,
          #     Range.new(
          #       Position.from_offset(source.code, soff),
          #       Position.from_offset(source.code, eoff)
          #     )
          #   )
          # end
        end

        # @param name [String]
        # @param top [AST::Node]
        # @return [Array<AST::Node>]
        def inner_node_references name, top
          # result = []
          # if top.is_a?(AST::Node) && top.to_s.include?(":#{name}")
          #   result.push top if top.children.any? { |c| c.to_s == name }
          #   top.children.each { |c| result.concat inner_node_references(name, c) }
          # end
          # result
        end

        def chain *args
          # NodeChainer.chain *args
        end

        def process_node *args
          # Solargraph::Parser::Legacy::NodeProcessor.process *args
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
          st = Position.new(node.first_lineno, node.first_column)
          en = Position.new(node.last_lineno, node.last_column)
          Range.new(st, en)
        end
      end
    end
  end
end
