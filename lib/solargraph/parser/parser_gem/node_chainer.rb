# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      # A factory for generating chains from nodes.
      #
      class NodeChainer
        include NodeMethods
        Chain = Source::Chain

        # @param node [Parser::AST::Node]
        # @param filename [String, nil]
        # @param parent [Parser::AST::Node, nil]
        def initialize node, filename = nil, parent = nil
          @node = node
          @filename = filename
          @parent = parent
        end

        # @return [Source::Chain]
        def chain
          links = generate_links(@node)
          Chain.new(links, @node, (Parser.is_ast_node?(@node) && @node.type == :splat))
        end

        class << self
          # @param node [Parser::AST::Node]
          # @param filename [String, nil]
          # @param parent [Parser::AST::Node, nil]
          # @return [Source::Chain]
          def chain node, filename = nil, parent = nil
            NodeChainer.new(node, filename, parent).chain
          end

          # @param code [String]
          # @return [Source::Chain]
          def load_string(code)
            node = Parser.parse(code.sub(/\.$/, ''))
            chain = NodeChainer.new(node).chain
            chain.links.push(Chain::Link.new) if code.end_with?('.')
            chain
          end
        end

        private

        # @param n [Parser::AST::Node]
        # @return [Array<Chain::Link>]
        def generate_links n
          return [] unless n.is_a?(::Parser::AST::Node)
          return generate_links(n.children[0]) if n.type == :splat
          # @type [Array<Chain::Link>]
          result = []
          if n.type == :block
            result.concat NodeChainer.chain(n.children[0], @filename, n).links
          elsif n.type == :send
            if n.children[0].is_a?(::Parser::AST::Node)
              result.concat generate_links(n.children[0])
              result.push Chain::Call.new(n.children[1].to_s, node_args(n), passed_block(n))
            elsif n.children[0].nil?
              args = []
              n.children[2..-1].each do |c|
                args.push NodeChainer.chain(c, @filename, n)
              end
              result.push Chain::Call.new(n.children[1].to_s, node_args(n), passed_block(n))
            else
              raise "No idea what to do with #{n}"
            end
          elsif n.type == :csend
            if n.children[0].is_a?(::Parser::AST::Node)
              result.concat generate_links(n.children[0])
              result.push Chain::QCall.new(n.children[1].to_s, node_args(n))
            elsif n.children[0].nil?
              result.push Chain::QCall.new(n.children[1].to_s, node_args(n))
            else
              raise "No idea what to do with #{n}"
            end
          elsif n.type == :self
            result.push Chain::Head.new('self')
          elsif n.type == :zsuper
            result.push Chain::ZSuper.new('super')
          elsif n.type == :super
            args = n.children.map { |c| NodeChainer.chain(c, @filename, n) }
            result.push Chain::Call.new('super', args)
          elsif n.type == :yield
            args = n.children.map { |c| NodeChainer.chain(c, @filename, n) }
            result.push Chain::Call.new('yield', args)
          elsif n.type == :const
            const = unpack_name(n)
            result.push Chain::Constant.new(const)
          elsif [:lvar, :lvasgn].include?(n.type)
            result.push Chain::Call.new(n.children[0].to_s)
          elsif [:ivar, :ivasgn].include?(n.type)
            result.push Chain::InstanceVariable.new(n.children[0].to_s)
          elsif [:cvar, :cvasgn].include?(n.type)
            result.push Chain::ClassVariable.new(n.children[0].to_s)
          elsif [:gvar, :gvasgn].include?(n.type)
            result.push Chain::GlobalVariable.new(n.children[0].to_s)
          elsif n.type == :or_asgn
            result.concat generate_links n.children[1]
          elsif [:class, :module, :def, :defs].include?(n.type)
            # @todo Undefined or what?
            result.push Chain::UNDEFINED_CALL
          elsif n.type == :and
            result.concat generate_links(n.children.last)
          elsif n.type == :or
            result.push Chain::Or.new([NodeChainer.chain(n.children[0], @filename), NodeChainer.chain(n.children[1], @filename, n)])
          elsif n.type == :if
            result.push Chain::If.new([NodeChainer.chain(n.children[1], @filename), NodeChainer.chain(n.children[2], @filename, n)])
          elsif [:begin, :kwbegin].include?(n.type)
            result.concat generate_links(n.children.last)
          elsif n.type == :block_pass
            block_variable_name_node = n.children[0]
            if block_variable_name_node.nil?
              # anonymous block forwarding (e.g., "&")
              # added in Ruby 3.1 - https://bugs.ruby-lang.org/issues/11256
              result.push Chain::BlockVariable.new(nil)
            else
              if block_variable_name_node.type == :sym
                result.push Chain::BlockSymbol.new("#{block_variable_name_node.children[0].to_s}")
              else
                result.push Chain::BlockVariable.new("&#{block_variable_name_node.children[0].to_s}")
              end
            end
          elsif n.type == :hash
            result.push Chain::Hash.new('::Hash', n, hash_is_splatted?(n))
          elsif n.type == :array
            chained_children = n.children.map { |c| NodeChainer.chain(c) }
            result.push Source::Chain::Array.new(chained_children, n)
          else
            lit = infer_literal_node_type(n)
            result.push (lit ? Chain::Literal.new(lit, n) : Chain::Link.new)
          end
          result
        end

        # @param node [Parser::AST::Node]
        def hash_is_splatted? node
          return false unless Parser.is_ast_node?(node) && node.type == :hash
          return false unless Parser.is_ast_node?(node.children.last) && node.children.last.type == :kwsplat
          return false if Parser.is_ast_node?(node.children.last.children[0]) && node.children.last.children[0].type == :hash
          true
        end

        # @param node [Parser::AST::Node]
        # @return [Source::Chain, nil]
        def passed_block node
          return unless node == @node && @parent&.type == :block

          NodeChainer.chain(@parent.children[2], @filename)
        end

        # @param node [Parser::AST::Node]
        # @return [Array<Source::Chain>]
        def node_args node
          node.children[2..-1].map do |child|
            NodeChainer.chain(child, @filename, node)
          end
        end
      end
    end
  end
end
