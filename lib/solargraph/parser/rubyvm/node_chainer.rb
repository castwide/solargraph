# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      # A factory for generating chains from nodes.
      #
      class NodeChainer
        include Rubyvm::NodeMethods

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
          Chain.new(links)
        end

        class << self
          # @param node [Parser::AST::Node]
          # @param filename [String]
          # @return [Chain]
          def chain node, filename = nil, in_block = false
            NodeChainer.new(node, filename, in_block).chain
          end

          # @param code [String]
          # @return [Chain]
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
          return [] unless Parser.is_ast_node?(n)
          return generate_links(n.children[2]) if n.type == :SCOPE
          result = []
          if n.type == :ITER
            @in_block = true
            result.concat generate_links(n.children[0])
            @in_block = false
          elsif n.type == :CALL
            n.children[0..-3].each do |c|
              result.concat generate_links(c)
            end
            args = []
            if n.children.last && n.children.last.type == :ARRAY
              n.children.last.children[0..-2].each do |c|
                args.push NodeChainer.chain(c)
              end
            elsif n.children.last && n.children.last.type == :BLOCK_PASS
              # @todo This probably shouldn't be a BlockVariable, if this is
              #   necessary at all.
              # args.push Chain::BlockVariable.new("&#{n.children.last.children[1].children[0].to_s}")
            end
            result.push Chain::Call.new(n.children[-2].to_s, args, @in_block || block_passed?(n))
            # if n.children.last && n.children.last.type == :BLOCK_PASS
            #   result.push Chain::BlockVariable.new("&#{n.children.last.children[0].to_s}")
            # end
            # result.concat generate_links(n.children.last)
            # if Parser.is_ast_node?(n.children[0])
            #   result.concat generate_links(n.children[0])
            #   args = []
            #   n.children[2..-1].each do |c|
            #     args.push NodeChainer.chain(c)
            #   end
            #   result.push Chain::Call.new(n.children[1].to_s, args, @in_block || block_passed?(n))
            # elsif n.children[0].nil?
            #   args = []
            #   n.children[2..-1].each do |c|
            #     args.push NodeChainer.chain(c)
            #   end
            #   result.push Chain::Call.new(n.children[1].to_s, args, @in_block || block_passed?(n))
            # else
            #   raise "No idea what to do with #{n}"
            # end
          elsif n.type == :VCALL || n.type == :FCALL
            result.push Chain::Call.new(n.children[0].to_s, [], @in_block || block_passed?(n))
          elsif n.type == :SELF
            result.push Chain::Head.new('self')
          elsif n.type == :ZSUPER
            result.push Chain::Head.new('super')
          elsif [:COLON2, :COLON3, :CONST].include?(n.type)
            const = unpack_name(n)
            result.push Chain::Constant.new(const)
          elsif [:LVAR, :LASGN].include?(n.type)
            result.push Chain::Call.new(n.children[0].to_s)
          elsif [:IVAR, :IASGN].include?(n.type)
            result.push Chain::InstanceVariable.new(n.children[0].to_s)
          elsif [:CVAR, :CVASGN].include?(n.type)
            result.push Chain::ClassVariable.new(n.children[0].to_s)
          elsif [:GVAR, :GASGN].include?(n.type)
            result.push Chain::GlobalVariable.new(n.children[0].to_s)
          elsif n.type == :OP_ASGN_OR
            result.concat generate_links n.children[2]
          elsif [:class, :module, :def, :defs].include?(n.type)
            # @todo Undefined or what?
            result.push Chain::UNDEFINED_CALL
          elsif n.type == :AND
            result.concat generate_links(n.children.last)
          elsif n.type == :OR
            result.push Chain::Or.new([NodeChainer.chain(n.children[0], @filename), NodeChainer.chain(n.children[1], @filename)])
          # elsif [:begin, :kwbegin].include?(n.type)
          elsif [:BEGIN].include?(n.type)
            result.concat generate_links(n.children[0])
          elsif n.type == :BLOCK_PASS
            result.push Chain::BlockVariable.new("&#{n.children[1].children[0].to_s}")
          else
            lit = infer_literal_node_type(n)
            result.push (lit ? Chain::Literal.new(lit) : Chain::Link.new)
          end
          result
        end

        def block_passed? node
          node.children.last.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.children.last.type == :BLOCK_PASS
        end
      end
    end
  end
end
