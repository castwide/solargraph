module Solargraph
  module Pin
    class Method < BaseMethod
      include Source::NodeMethods

      # @return [Array<String>]
      attr_reader :parameters

      # @return [Parser::AST::Node]
      attr_reader :node

      def initialize location, namespace, name, comments, scope, visibility, args, node = nil
        super(location, namespace, name, comments)
        @scope = scope
        @visibility = visibility
        @parameters = args
        @node = node
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map{|p| p.split(/[ =:]/).first}
      end

      def kind
        Solargraph::Pin::METHOD
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def context
        @context ||= begin
          if scope == :class
            # @todo Determine whether the namespace is a class or a module
            ComplexType.parse("Class<#{namespace}>")
          else
            ComplexType.parse(namespace)
          end
        end
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      def symbol_kind
        LanguageServer::SymbolKinds::METHOD
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          param_tags = docstring.tags(:param)
          unless param_tags.nil? or param_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Params:\n"
            lines = []
            param_tags.each do |p|
              l = "* #{p.name}"
              l += " [#{p.types.join(', ')}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
        end
        @documentation
      end

      def nearly? other
        return false unless super
        parameters == other.parameters and
          scope == other.scope and
          visibility == other.visibility
      end

      def typify api_map
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map)
        return type unless type.nil?
        ComplexType::UNDEFINED
      end

      def probe api_map
        infer_from_return_nodes(api_map)
      end

      # @deprecated Use #typify and/or #probe instead
      def infer api_map
        STDERR.puts 'WARNING: Pin #infer methods are deprecated. Use #typify or #probe instead.'
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map)
        return type unless type.nil?
        infer_from_return_nodes(api_map)
      end

      def try_merge! pin
        return false unless super
        @node = pin.node
        true
      end

      private

      # @return [Parser::AST:Node, nil]
      def method_body_node
        return nil if node.nil?
        return node.children[2] if node.type == :def
        return node.children[3] if node.type == :defs
        nil
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_from_return_nodes api_map
        result = []
        returns_from(method_body_node).each do |n|
          next if n.loc.nil?
          clip = api_map.clip_at(
            location.filename,
            [n.loc.expression.last_line, n.loc.expression.last_column]
          )
          chain = Solargraph::Source::NodeChainer.chain(n, location.filename)
          type = chain.infer(api_map, self, clip.locals)
          result.push type unless type.undefined?
        end
        return ComplexType::UNDEFINED if result.empty?
        ComplexType.parse(*result.map(&:tag))
      end
    end
  end
end
