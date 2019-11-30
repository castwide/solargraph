# frozen_string_literal: true

module Solargraph
  module Pin
    class Method < BaseMethod
      # include Source::NodeMethods

      # @return [Array<String>]
      attr_reader :parameters

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param args [Array<String>]
      # @param node [Parser::AST::Node, nil]
      def initialize parameters: [], node: nil, **splat
        super(splat)
        @parameters = parameters
        @node = node
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
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
              l += " [#{escape_brackets(p.types.join(', '))}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
        end
        @documentation.to_s
      end

      def nearly? other
        return false unless super
        parameters == other.parameters and
          scope == other.scope and
          visibility == other.visibility
      end

      def probe api_map
        infer_from_return_nodes(api_map)
      end

      def try_merge! pin
        return false unless super
        @node = pin.node
        true
      end

      # @return [Array<Pin::Method>]
      def overloads
        @overloads ||= docstring.tags(:overload).map do |tag|
          Solargraph::Pin::Method.new(
            name: name,
            closure: self,
            # args: tag.parameters.map(&:first),
            parameters: tag.parameters.map do |src|
              Pin::Parameter.new(
                location: location,
                closure: self,
                comments: tag.docstring.all.to_s,
                name: src.first,
                presence: location ? location.range : nil,
                decl: :arg
              )
            end,
            comments: tag.docstring.all.to_s
          )
        end
      end

      private

      # @return [Parser::AST::Node, nil]
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
        has_nil = false
        Parser.returns_from(method_body_node).each do |n|
          if n.nil? || n.type == :nil
            has_nil = true
            next
          end
          next if n.loc.nil? || n.loc.expression.nil?
          clip = api_map.clip_at(
            location.filename,
            [n.loc.expression.last_line, n.loc.expression.last_column]
          )
          type = clip.infer
          result.push type unless type.undefined?
        end
        result.push ComplexType::NIL if has_nil
        return ComplexType::UNDEFINED if result.empty?
        ComplexType.try_parse(*result.map(&:tag).uniq)
      end
    end
  end
end
