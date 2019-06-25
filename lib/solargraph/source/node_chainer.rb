# frozen_string_literal: true

module Solargraph
  class Source
    # A factory for generating chains from nodes.
    #
    class NodeChainer
      include Source::NodeMethods

      # @param node [Parser::AST::Node]
      # @param filename [String]
      def initialize node, filename = nil
        @node = node
        @filename = filename
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
        def chain node, filename = nil
          NodeChainer.new(node, filename).chain
        end

        # @param code [String]
        # @return [Chain]
        def load_string(code)
          node = Source.parse(code.sub(/\.$/, ''))
          chain = NodeChainer.new(node).chain
          chain.links.push(Chain::Link.new) if code.end_with?('.')
          chain
        end
      end

      private

      # @param n [Parser::AST::Node]
      # @return [Array<Chain::Link>]
      def generate_links n
        return [] unless n.is_a?(Parser::AST::Node)
        return generate_links(n.children[0]) if n.type == :begin
        result = []
        if n.type == :block
          result.concat generate_links(n.children[0])
        elsif n.type == :send
          if n.children[0].is_a?(Parser::AST::Node)
            result.concat generate_links(n.children[0])
            args = []
            n.children[2..-1].each do |c|
              args.push NodeChainer.chain(c)
            end
            result.push Chain::Call.new(n.children[1].to_s, args)
          elsif n.children[0].nil?
            args = []
            n.children[2..-1].each do |c|
              args.push NodeChainer.chain(c)
            end
            result.push Chain::Call.new(n.children[1].to_s, args)
          else
            raise "No idea what to do with #{n}"
          end
        elsif n.type == :self
          result.push Chain::Head.new('self')
        elsif n.type == :zsuper
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
        else
          lit = infer_literal_node_type(n)
          result.push (lit ? Chain::Literal.new(lit) : Chain::Link.new)
        end
        result
      end
    end
  end
end
