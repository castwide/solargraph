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

        def returns_from node
          if node.type == :SCOPE
            node.children.select { |n| n.is_a?(RubyVM::AbstractSyntaxTree::Node) }.map { |n| DeepInference.get_return_nodes(n) }.flatten
          else
            DeepInference.get_return_nodes(node)
          end
        end

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
          top.children.select { |c| c.is_a?(Symbol) }.any? { |c| c.to_s == name }
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

        module DeepInference
          class << self
            CONDITIONAL = [:IF, :UNLESS]
            REDUCEABLE = [:BLOCK]
            SKIPPABLE = [:DEFN, :DEFS, :CLASS, :SCLASS, :MODULE]

            # @param node [Parser::AST::Node]
            # @return [Array<Parser::AST::Node>]
            def get_return_nodes node
              return [] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              if REDUCEABLE.include?(node.type)
                result.concat get_return_nodes_from_children(node)
              elsif CONDITIONAL.include?(node.type)
                result.concat reduce_to_value_nodes(node.children[1..-1])
              elsif node.type == :AND || node.type == :OR
                result.concat reduce_to_value_nodes(node.children)
              elsif node.type == :RETURN
                result.concat reduce_to_value_nodes([node.children[0]])
              elsif node.type == :ITER
                result.concat reduce_to_value_nodes([node.children[0]])
                result.concat get_return_nodes_only(node.children[1])
              else
                result.push node
              end
              result
            end

            private

            def get_return_nodes_from_children parent
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each_with_index do |node, idx|
                if node.type == :BLOCK
                  result.concat get_return_nodes_only(node.children[2])
                elsif SKIPPABLE.include?(node.type)
                  next
                elsif CONDITIONAL.include?(node.type)
                  result.concat get_return_nodes_only(node)
                elsif node.type == :RETURN
                  result.concat reduce_to_value_nodes([node.children[0]])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat get_return_nodes_only(node)
                end
                result.concat reduce_to_value_nodes([nodes.last]) if idx == nodes.length - 1
              end
              result
            end

            def get_return_nodes_only parent
              return [] unless parent.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result = []
              nodes = parent.children.select{|n| n.is_a?(RubyVM::AbstractSyntaxTree::Node)}
              nodes.each do |node|
                next if SKIPPABLE.include?(node.type)
                if node.type == :RETURN
                  result.concat reduce_to_value_nodes([node.children[0]])
                  # Return the result here because the rest of the code is
                  # unreachable
                  return result
                else
                  result.concat get_return_nodes_only(node)
                end
              end
              result
            end

            def reduce_to_value_nodes nodes
              result = []
              nodes.each do |node|
                if !node.is_a?(RubyVM::AbstractSyntaxTree::Node)
                  result.push nil
                elsif REDUCEABLE.include?(node.type)
                  result.concat get_return_nodes_from_children(node)
                elsif CONDITIONAL.include?(node.type)
                  result.concat reduce_to_value_nodes(node.children[1..-1])
                elsif node.type == :RETURN
                  if node.children[0].nil?
                    result.push nil
                  else
                    result.concat get_return_nodes(node.children[0])
                  end
                elsif node.type == :AND || node.type == :OR
                  result.concat reduce_to_value_nodes(node.children)
                elsif node.type == :BLOCK
                  result.concat get_return_nodes_only(node.children[2])
                else
                  result.push node
                end
              end
              result
            end
          end
        end
      end
    end
  end
end
