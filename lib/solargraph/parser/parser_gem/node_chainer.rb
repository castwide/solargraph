# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      # A factory for generating chains from nodes.
      #
      class NodeChainer
        include NodeMethods

        Chain = Source::Chain

        # @param node [Parser::AST::Node, nil]
        # @param filename [String, nil]
        # @param parent [Parser::AST::Node, nil]
        # @param tree [Array<Parser::AST::Node>, nil]
        def initialize node, filename = nil, parent = nil, tree = nil
          @node = node
          @filename = filename
          @parent = parent
          @tree = tree
        end

        # @return [Source::Chain]
        def chain
          links = generate_links(@node)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          Chain.new(links, @node, Parser.is_ast_node?(@node) && @node.type == :splat)
        end

        class << self
          # @param node [Parser::AST::Node]
          # @param filename [String, nil]
          # @param parent [Parser::AST::Node, nil]
          # @param tree [Parser::AST::Node, nil]
          # @return [Source::Chain]
          def chain node, filename = nil, parent = nil, tree = nil
            NodeChainer.new(node, filename, parent, tree).chain
          end

          # @param code [String]
          # @param filename [String]
          # @param starting_line [Integer]
          #
          # @return [Source::Chain]
          def load_string code, filename, starting_line
            node = Parser.parse(code.sub(/\.$/, ''), filename, starting_line)
            chain = NodeChainer.new(node).chain
            chain.links.push(Chain::Link.new) if code.end_with?('.')
            chain
          end
        end

        private

        # @param n [Parser::AST::Node, nil]
        # @return [Array<Chain::Link>]
        def generate_links n
          return [] unless n.is_a?(::Parser::AST::Node)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          #   also needs https://github.com/castwide/solargraph/pull/1416
          return generate_links(n.children[0]) if n.type == :splat
          # @type [Array<Chain::Link>]
          result = []
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          if n.type == :block
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            result.concat NodeChainer.chain(n.children[0], @filename, n).links
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :send
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            if n.children[0].is_a?(::Parser::AST::Node)
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              #   also needs https://github.com/castwide/solargraph/pull/1416
              result.concat generate_links(n.children[0])
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              result.push Chain::Call.new(n.children[1].to_s, Location.from_node(n), node_args(n), passed_block(n))
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            elsif n.children[0].nil?
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              #   also needs https://github.com/castwide/solargraph/pull/1416
              n.children[2..].map do |c|
                NodeChainer.chain(c, @filename, n)
              end
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              result.push Chain::Call.new(n.children[1].to_s, Location.from_node(n), node_args(n), passed_block(n))
            else
              raise "No idea what to do with #{n}"
            end
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :csend
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            if n.children[0].is_a?(::Parser::AST::Node)
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              #   also needs https://github.com/castwide/solargraph/pull/1416
              result.concat generate_links(n.children[0])
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              result.push Chain::QCall.new(n.children[1].to_s, Location.from_node(n), node_args(n))
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            elsif n.children[0].nil?
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              result.push Chain::QCall.new(n.children[1].to_s, Location.from_node(n), node_args(n))
            else
              raise "No idea what to do with #{n}"
            end
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :self
            result.push Chain::Head.new('self')
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :zsuper
            result.push Chain::ZSuper.new('super')
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :super
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            args = n.children.map { |c| NodeChainer.chain(c, @filename, n) }
            result.push Chain::Call.new('super', Location.from_node(n), args)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :yield
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            args = n.children.map { |c| NodeChainer.chain(c, @filename, n) }
            result.push Chain::Call.new('yield', Location.from_node(n), args)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :const
            const = unpack_name(n)
            result.push Chain::Constant.new(const)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[lvar lvasgn].include?(n.type)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Chain::Call.new(n.children[0].to_s, Location.from_node(n))
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[ivar ivasgn].include?(n.type)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Chain::InstanceVariable.new(n.children[0].to_s, n, Location.from_node(n))
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[cvar cvasgn].include?(n.type)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Chain::ClassVariable.new(n.children[0].to_s)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[gvar gvasgn].include?(n.type)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Chain::GlobalVariable.new(n.children[0].to_s)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :or_asgn
            # @bar ||= 123 translates to:
            #
            # s(:or_asgn,
            #   s(:ivasgn, :@bar),
            #   s(:int, 123))
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            lhs_chain = NodeChainer.chain n.children[0] # s(:ivasgn, :@bar)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            rhs_chain = NodeChainer.chain n.children[1] # s(:int, 123)
            or_link = Chain::Or.new([lhs_chain, rhs_chain])
            # this is just for a call chain, so we don't need to record the assignment
            result.push(or_link)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[class module def defs].include?(n.type)
            # @todo Undefined or what?
            result.push Chain::UNDEFINED_CALL
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :and
            # @sg-ignore Wrong argument type for Solargraph::Parser::ParserGem::NodeChainer#generate_links: n expected
            #   Parser::AST::Node, received Parser::AST::Node, Integer, Float, Rational, Complex, String, Symbol,
            #   NilClass, nil
            result.concat generate_links(n.children.last)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :or
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            result.push Chain::Or.new([NodeChainer.chain(n.children[0], @filename),
                                       # @sg-ignore https://github.com/castwide/solargraph/pull/1418
                                       #   also needs https://github.com/castwide/solargraph/pull/1416
                                       NodeChainer.chain(n.children[1], @filename, n)])
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :if
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            then_clause = if n.children[1]
                            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
                            #   also needs https://github.com/castwide/solargraph/pull/1416
                            NodeChainer.chain(n.children[1], @filename, n)
                          else
                            Source::Chain.new([Source::Chain::Literal.new('nil', nil)], n)
                          end
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            else_clause = if n.children[2]
                            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
                            #   also needs https://github.com/castwide/solargraph/pull/1416
                            NodeChainer.chain(n.children[2], @filename, n)
                          else
                            Source::Chain.new([Source::Chain::Literal.new('nil', nil)], n)
                          end
            result.push Chain::If.new([then_clause, else_clause])
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif %i[begin kwbegin].include?(n.type)
            # @sg-ignore Wrong argument type for Solargraph::Parser::ParserGem::NodeChainer#generate_links: n expected
            #   Parser::AST::Node, received Parser::AST::Node, Integer, Float, Rational, Complex, String, Symbol,
            #   NilClass, nil
            result.concat generate_links(n.children.last)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :block_pass
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            block_variable_name_node = n.children[0]
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            if block_variable_name_node.nil?
              # anonymous block forwarding (e.g., "&")
              # added in Ruby 3.1 - https://bugs.ruby-lang.org/issues/11256
              result.push Chain::BlockVariable.new(nil)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            elsif block_variable_name_node.type == :sym
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              #   also needs https://github.com/castwide/solargraph/pull/1416
              result.push Chain::BlockSymbol.new(block_variable_name_node.children[0].to_s)
            else
              # @sg-ignore https://github.com/castwide/solargraph/pull/1418
              #   also needs https://github.com/castwide/solargraph/pull/1416
              result.push Chain::BlockVariable.new("&#{block_variable_name_node.children[0]}")
            end
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :hash
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Chain::Hash.new('::Hash', n, hash_is_splatted?(n))
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          elsif n.type == :array
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            chained_children = n.children.map { |c| NodeChainer.chain(c) }
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            result.push Source::Chain::Array.new(chained_children, n)
          elsif inside_method_call? # If the node is inside a method call, it may be a parameter.
            lit = infer_literal_node_type(n)
            if lit
              # @sg-ignore https://github.com/castwide/solargraph/pull/1245
              method_call_chain = NodeChainer.chain(send_node, @filename, nil, [])
              literal = Chain::Literal.new(lit, n)
              result.push Chain::Parameter.new(literal, method_call_chain)
            end
          else
            lit = infer_literal_node_type(n)
            result.push(lit ? Chain::Literal.new(lit, n) : Chain::Link.new)
            # result.push Chain::Link.new
          end
          result
        end

        def inside_method_call?
          !send_node.nil? && send_node != @node
        end

        # @return [Parser::AST::Node, nil]
        # @sg-ignore https://github.com/castwide/solargraph/pull/1421
        def send_node
          # @sg-ignore https://github.com/castwide/solargraph/pull/1421
          @send_node ||= @tree&.find { |n| n.type == :send }
        end

        # @param node [Parser::AST::Node]
        def hash_is_splatted? node
          return false unless Parser.is_ast_node?(node) && node.type == :hash
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          #   also needs https://github.com/castwide/solargraph/pull/1416
          return false unless Parser.is_ast_node?(node.children.last) && node.children.last.type == :kwsplat
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          #   also needs https://github.com/castwide/solargraph/pull/1416
          if Parser.is_ast_node?(node.children.last.children[0]) && node.children.last.children[0].type == :hash
            return false
          end
          true
        end

        # @param node [Parser::AST::Node]
        # @return [Source::Chain, nil]
        def passed_block node
          return unless node == @node && @parent&.type == :block

          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          #   also needs https://github.com/castwide/solargraph/pull/1416
          NodeChainer.chain(@parent.children[2], @filename)
        end

        # @param node [Parser::AST::Node]
        # @sg-ignore https://github.com/castwide/solargraph/pull/1391
        # @return [Array<Source::Chain>]
        def node_args node
          # @sg-ignore https://github.com/castwide/solargraph/pull/1418
          #   also needs https://github.com/castwide/solargraph/pull/1416
          node.children[2..].map do |child|
            NodeChainer.chain(child, @filename, node)
          end
        end
      end
    end
  end
end
