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

      # @param node [Parser::AST::Node]
      def initialize node = Parser::AST::Node.new('')
        @node = node
        @links = generate_links @node
      end

      # @param api_map [ApiMap]
      # @param context [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def define_with api_map, context, locals
        inner_define_with links, api_map, context, locals
      end

      # @param api_map [ApiMap]
      # @param context [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer_type_with api_map, context, locals
        # @todo Perform link inference
        inner_infer_type_with(links, api_map, context, locals)
      end

      def infer_base_type_with api_map, context, locals
        inner_infer_type_with(links[0..-2], api_map, context, locals)
      end

      private

      def inner_infer_type_with array, api_map, context, locals
        type = ComplexType::UNDEFINED
        pins = inner_define_with(array, api_map, context, locals)
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        type
      end

      def inner_define_with array, api_map, context, locals
        return [] if array.empty?
        head = true
        type = ComplexType::UNDEFINED
        # @param link [Chain::Link]
        array[0..-2].each do |link|
          pins = link.resolve_pins(api_map, context, head ? locals : [])
          return [] if pins.empty?
          pins.each do |pin|
            # type = deeply_infer(pin, api_map, context, locals)
            type = pin.infer(api_map)
            break unless type.undefined?
          end
          return [] if type.undefined?
          context = Pin::ProxyType.anonymous(type)
        end
        array.last.resolve_pins(api_map, context, head ? locals: [])
      end

      # @param pin [Pin::Base]
      # @return [ComplexType]
      # def deeply_infer pin, api_map, context, locals
      #   return pin.return_complex_type unless pin.return_complex_type.undefined?
      #   # @todo Deep inference
      #   ComplexType::UNDEFINED
      # end

      # @return [AST::Parser::Node]
      attr_reader :node

      # @param n [AST::Node]
      # @return [Array<Chain::Link>]
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
          result.push (lit ? Literal.new(lit) : Link.new)
        end
        result
      end

      class << self
        # @param code [String]
        # @return [Chain]
        def load_string(code)
          # @todo Parsing with Source might be heavier than necessary.
          #   We don't care about pins here, only the node.
          source = Source.load_string(code)
          Chain.new(source.node)
        end
      end
    end
  end
end
