# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      # A factory for generating chains from nodes.
      #
      class NodeChainer
        include NodeMethods
        Chain = Source::Chain

        # @param node [Parser::AST::Node]
        # @param filename [String]
        def initialize node, filename = nil, in_block = false
          @node = node
          @filename = filename
          @in_block = in_block
        end

        # @return [Source::Chain]
        def chain
          links = generate_links(@node)
          Chain.new(links, @node)
        end

        class << self
          # @param node [Parser::AST::Node]
          # @param filename [String]
          # @return [Source::Chain]
          def chain node, filename = nil, in_block = false
            NodeChainer.new(node, filename, in_block).chain
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
          return generate_links(n.children[0]) if n.type == :begin
          result = []
          if n.type == :block
            @in_block = true
            result.concat generate_links(n.children[0])
            @in_block = false
          elsif n.type == :send
            if n.children[0].is_a?(::Parser::AST::Node)
              result.concat generate_links(n.children[0])
              args = []
              n.children[2..-1].each do |c|
                args.push NodeChainer.chain(c)
              end
              result.push Chain::Call.new(n.children[1].to_s, args, @in_block || block_passed?(n))
            elsif n.children[0].nil?
              args = []
              n.children[2..-1].each do |c|
                args.push NodeChainer.chain(c)
              end
              result.push Chain::Call.new(n.children[1].to_s, args, @in_block || block_passed?(n))
            else
              raise "No idea what to do with #{n}"
            end
          elsif n.type == :self
            result.push Chain::Head.new('self')
          elsif [:super, :zsuper].include?(n.type)
            result.push Chain::Head.new('super')
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
            result.push Chain::Or.new([NodeChainer.chain(n.children[0], @filename), NodeChainer.chain(n.children[1], @filename)])
          elsif [:begin, :kwbegin].include?(n.type)
            result.concat generate_links(n.children[0])
          elsif n.type == :block_pass
            result.push Chain::BlockVariable.new("&#{n.children[0].children[0].to_s}")
          else
            lit = infer_literal_node_type(n)
            result.push (lit ? Chain::Literal.new(lit) : Chain::Link.new)
          end
          result
        end

        def block_passed? node
          node.children.last.is_a?(::Parser::AST::Node) && node.children.last.type == :block_pass
        end
      end
    end
  end
end
