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

        # @param n [Parser::AST::Node]
        # @return [Array<Chain::Link>]
        def generate_links n
          return [] unless n.is_a?(::Parser::AST::Node)
          # s(:splat, value) - an anonymous splat in an mlhs has no value
          if n in [:splat, *rest]
            return (rest in [::Parser::AST::Node => splatted, *]) ? generate_links(splatted) : [] # rubocop:disable Style/RedundantParentheses
          end
          # @type [Array<Chain::Link>]
          result = []
          case n
          in [:block, ::Parser::AST::Node => call, *]
            result.concat NodeChainer.chain(call, @filename, n).links
          in [:send, ::Parser::AST::Node => receiver, Symbol => method_name, *]
            result.concat generate_links(receiver)
            result.push Chain::Call.new(method_name.to_s, Location.from_node(n), node_args(n), passed_block(n))
          in [:send, nil, Symbol => method_name, *args]
            # @sg-ignore Need to add nil check here
            args.map do |c|
              NodeChainer.chain(c, @filename, n)
            end
            result.push Chain::Call.new(method_name.to_s, Location.from_node(n), node_args(n), passed_block(n))
          in [:send, *]
            raise "No idea what to do with #{n}"
          in [:csend, ::Parser::AST::Node => receiver, Symbol => method_name, *]
            result.concat generate_links(receiver)
            result.push Chain::QCall.new(method_name.to_s, Location.from_node(n), node_args(n))
          in [:csend, nil, Symbol => method_name, *]
            result.push Chain::QCall.new(method_name.to_s, Location.from_node(n), node_args(n))
          in [:csend, *]
            raise "No idea what to do with #{n}"
          in [:self, *]
            result.push Chain::Head.new('self')
          in [:zsuper, *]
            result.push Chain::ZSuper.new('super')
          in [:super, *]
            # s(:super, *args) - every argument is a node
            args = n.children.map do |child|
              # raises NoMatchingPatternError on a non-node child
              child => ::Parser::AST::Node => c
              NodeChainer.chain(c, @filename, n)
            end
            result.push Chain::Call.new('super', Location.from_node(n), args)
          in [:yield, *]
            # s(:yield, *args) - every argument is a node
            args = n.children.map do |child|
              # raises NoMatchingPatternError on a non-node child
              child => ::Parser::AST::Node => c
              NodeChainer.chain(c, @filename, n)
            end
            result.push Chain::Call.new('yield', Location.from_node(n), args)
          in [:const, *]
            const = unpack_name(n)
            result.push Chain::Constant.new(const)
          in [:lvar | :lvasgn, Symbol => name, *]
            result.push Chain::Call.new(name.to_s, Location.from_node(n))
          in [:ivar | :ivasgn, Symbol => name, *]
            result.push Chain::InstanceVariable.new(name.to_s, n, Location.from_node(n))
          in [:cvar | :cvasgn, Symbol => name, *]
            result.push Chain::ClassVariable.new(name.to_s)
          in [:gvar | :gvasgn, Symbol => name, *]
            result.push Chain::GlobalVariable.new(name.to_s)
          in [:or_asgn, ::Parser::AST::Node => lhs, ::Parser::AST::Node => rhs, *]
            # @bar ||= 123 translates to:
            #
            # s(:or_asgn,
            #   s(:ivasgn, :@bar),
            #   s(:int, 123))
            lhs_chain = NodeChainer.chain lhs # s(:ivasgn, :@bar)
            rhs_chain = NodeChainer.chain rhs # s(:int, 123)
            or_link = Chain::Or.new([lhs_chain, rhs_chain])
            # this is just for a call chain, so we don't need to record the assignment
            result.push(or_link)
          in [:class | :module | :def | :defs, *]
            # @todo Undefined or what?
            result.push Chain::UNDEFINED_CALL
          in [:and, *, ::Parser::AST::Node => last]
            result.concat generate_links(last)
          in [:or, ::Parser::AST::Node => lhs, ::Parser::AST::Node => rhs, *]
            result.push Chain::Or.new([NodeChainer.chain(lhs, @filename),
                                       NodeChainer.chain(rhs, @filename, n)])
          in [:if, _, ::Parser::AST::Node | nil => then_node, ::Parser::AST::Node | nil => else_node, *]
            then_clause = if then_node
                            NodeChainer.chain(then_node, @filename, n)
                          else
                            Source::Chain.new([Source::Chain::Literal.new('nil', nil)], n)
                          end
            else_clause = if else_node
                            NodeChainer.chain(else_node, @filename, n)
                          else
                            Source::Chain.new([Source::Chain::Literal.new('nil', nil)], n)
                          end
            result.push Chain::If.new([then_clause, else_clause])
          in [:begin | :kwbegin, *, ::Parser::AST::Node => last]
            result.concat generate_links(last)
          in [:begin | :kwbegin]
            # an empty begin...end has no links
          in [:block_pass, *]
            result.push block_pass_link(n)
          in [:hash, *]
            result.push Chain::Hash.new('::Hash', n, hash_is_splatted?(n))
          in [:array, *]
            # s(:array, *elements) - every element is a node
            chained_children = n.children.map do |child|
              # raises NoMatchingPatternError on a non-node child
              child => ::Parser::AST::Node => c
              NodeChainer.chain(c)
            end
            result.push Source::Chain::Array.new(chained_children, n)
          in _ if inside_method_call? # If the node is inside a method call, it may be a parameter.
            lit = infer_literal_node_type(n)
            if lit
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

        # @param block_pass [Parser::AST::Node]
        # @return [Chain::Link]
        def block_pass_link block_pass
          case block_pass
          in [_, [:sym, Symbol => symbol, *]]
            Chain::BlockSymbol.new(symbol.to_s)
          in [_, ::Parser::AST::Node => block_variable_name_node, *]
            # &blk passes s(:lvar, :blk); &method(:x) passes a send whose first child is nil
            variable_name = (block_variable_name_node in [_, value, *]) ? value : nil # rubocop:disable Style/RedundantParentheses
            Chain::BlockVariable.new("&#{variable_name}")
          else
            # anonymous block forwarding (e.g., "&")
            # added in Ruby 3.1 - https://bugs.ruby-lang.org/issues/11256
            Chain::BlockVariable.new(nil)
          end
        end

        def inside_method_call?
          !send_node.nil? && send_node != @node
        end

        # @return [Parser::AST::Node, nil]
        def send_node
          @send_node ||= @tree&.find { |n| n.type == :send }
        end

        # @param node [Parser::AST::Node]
        def hash_is_splatted? node
          # {**splatted} - s(:hash, *pairs, s(:kwsplat, splatted)), unless splatted is a hash literal
          return false unless node in ::Parser::AST::Node[:hash, *, ::Parser::AST::Node[:kwsplat, ::Parser::AST::Node => splatted, *]]

          !(splatted in ::Parser::AST::Node[:hash, *])
        end

        # @param node [Parser::AST::Node]
        # @return [Source::Chain, nil]
        def passed_block node
          # s(:block, call, args, body)
          return unless node == @node && (@parent in [:block, _, _, ::Parser::AST::Node | nil => body])

          # an empty block still passes a block, so it gets an empty chain, not nil
          body ? NodeChainer.chain(body, @filename) : Chain.new([])
        end

        # @param node [Parser::AST::Node]
        # @sg-ignore Need to add nil check here
        # @return [Array<Source::Chain>]
        def node_args node
          node => [_, _, _, *args]
          # @sg-ignore Need to add nil check here
          args.map do |child|
            NodeChainer.chain(child, @filename, node)
          end
        end
      end
    end
  end
end
