module Solargraph
  class Source
    class NodeChainer
      include Source::NodeMethods

      def initialize node, filename = nil
        @node = node
        @filename = filename
        # @source = source
        # @line = line
        # @column = column
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
        # @param filename [String, nil]
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
        return [] if n.nil?
        return generate_links(n.children[0]) if n.type == :begin
        # @todo This might not be right. It's weird either way.
        # return generate_links(n.children[2] || n.children[0]) if n.type == :block
        result = []
        if n.type == :block
          # result.concat generate_links(n.children[2])
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
          result.push Chain::Call.new('self')
        elsif n.type == :const
          # result.push Chain::Constant.new(unpack_name(n))
          const = unpack_name(n)
          parts = const.split('::')
          last = parts.pop
          result.push Chain::Constant.new(parts.join('::')) unless parts.empty?
          result.push Chain::Constant.new(last)
        elsif [:lvar, :lvasgn].include?(n.type)
          result.push Chain::Call.new(n.children[0].to_s)
        elsif [:ivar, :ivasgn].include?(n.type)
          result.push Chain::InstanceVariable.new(n.children[0].to_s)
        elsif [:cvar, :cvasgn].include?(n.type)
          result.push Chain::ClassVariable.new(n.children[0].to_s)
        elsif [:gvar, :gvasgn].include?(n.type)
          result.push Chain::GlobalVariable.new(n.children[0].to_s)
        elsif [:class, :module, :def, :defs].include?(n.type)
          # location = Solargraph::Location.new(@filename, Range.from_to(n.loc.expression.line, n.loc.expression.column, n.loc.expression.last_line, n.loc.expression.last_column))
          # result.push Chain::Definition.new(location)
          # @todo Undefined or what?
          result.push Chain::UNDEFINED_CALL
        else
          lit = infer_literal_node_type(n)
          result.push (lit ? Chain::Literal.new(lit) : Chain::Link.new)
        end
        result
      end
    end
  end
end
