module Solargraph
  module Pin
    class Method < Base
      include Source::NodeMethods

      # @return [Symbol] :instance or :class
      attr_reader :scope

      # @return [Symbol] :public, :private, or :protected
      attr_reader :visibility

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

      # @return [Integer]
      def symbol_kind
        LanguageServer::SymbolKinds::METHOD
      end

      def return_complex_type
        @return_complex_type ||= generate_complex_type
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

      def infer api_map
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map)
        return type unless type.nil?
        infer_from_return_nodes(api_map)
      end

      private

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:return)
        if tag.nil?
          ol = docstring.tag(:overload)
          tag = ol.tag(:return) unless ol.nil?
        end
        return ComplexType::UNDEFINED if tag.nil? or tag.types.nil? or tag.types.empty?
        begin
          ComplexType.parse *tag.types
        rescue Solargraph::ComplexTypeError => e
          STDERR.puts e.message
          ComplexType::UNDEFINED
        end
      end

      # @param api_map [ApiMap]
      def infer_from_return_nodes api_map
        return ComplexType::UNDEFINED if node.nil? || node.children[2].nil?
        result = []
        nodes = returns_from(node.children[2])
        nodes.each do |n|
          chain = Source::NodeChainer.chain(n)
          clip = api_map.clip_at(location.filename, Solargraph::Position.new(n.loc.expression.line, n.loc.expression.column))
          type = clip.infer
          result.push type unless type.undefined?
        end
        return ComplexType::UNDEFINED if result.empty?
        ComplexType.parse(*result.map(&:tag))
      end

      # @param [ApiMap]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
          # @todo Resolve the reference
          puts ref.owner.inspect
          parts = ref.owner.to_s.split(/[\.#]/)
          if parts.first.empty?
            path = "#{namespace}#{ref.owner.to_s}"
          else
            fqns = api_map.qualify(parts.first, namespace)
            return ComplexType::UNDEFINED if fqns.nil?
            path = fqns + ref.owner.to_s[parts.first.length] + parts.last
          end
          pins = api_map.get_path_pins(path)
          pins.each do |pin|
            type = pin.infer(api_map)
            return type unless type.undefined?
          end
        end
        nil
      end
    end
  end
end
