module Solargraph
  class Source
    class Chain
      autoload :Link, 'solargraph/source/chain/link'
      autoload :Call, 'solargraph/source/chain/call'
      autoload :Variable, 'solargraph/source/chain/variable'
      autoload :ClassVariable, 'solargraph/source/chain/class_variable'
      autoload :Constant, 'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :Literal, 'solargraph/source/chain/literal'

      include NodeMethods

      # @return [Array<Source::Chain::Link>]
      attr_reader :links

      def initialize node
        @node = node
        @links = generate_links node
      end

      private

      def generate_links n
        return generate_links(n.children[0]) if n.type == :block
        result = []
        if n.type == :send
          if n.children[0].is_a?(Parser::AST::Node)
            result.concat generate_links(n.children[0])
            args = []
            n.children[2..-1].each do |c|
              # @todo Handle link parameters
              # args.push Chain.new(source, c.loc.last_line - 1, c.loc.column)
            end
            result.push Call.new(n.children[1].to_s, args)
          elsif n.children[0].nil?
            args = []
            n.children[2..-1].each do |c|
              # @todo Handle link parameters
              # args.push Chain.new(source, c.loc.last_line - 1, c.loc.column)
            end
            result.push Call.new(n.children[1].to_s, args)
          else
            raise "No idea what to do with #{n}"
          end
        elsif n.type == :const
          result.push Constant.new(unpack_name(n))
        elsif n.type == :lvar
          result.push Call.new(n.children[0].to_s)
        elsif n.type == :ivar
          result.push InstanceVariable.new(n.children[0].to_s)
        elsif n.type == :cvar
          result.push ClassVariable.new(n.children[0].to_s)
        elsif [:ivar, :cvar, :gvar].include?(n.type)
          result.push Variable.new(n.children[0].to_s)
        else
          lit = infer_literal_node_type(n)
          result.push (lit ? Fragment::Literal.new(lit) : Fragment::Link.new)
        end
        result
      end
    end
  end
end
