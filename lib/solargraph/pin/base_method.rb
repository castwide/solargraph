# frozen_string_literal: true

module Solargraph
  module Pin
    # The base class for method and attribute pins.
    #
    class BaseMethod < Closure
      # @return [::Symbol] :public, :private, or :protected
      attr_reader :visibility

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param visibility [::Symbol] :public, :protected, or :private
      # @param explicit [Boolean]
      def initialize visibility: :public, explicit: true, **splat
        super(splat)
        @visibility = visibility
        @explicit = explicit
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def path
        @path ||= "#{namespace}#{(scope == :instance ? '#' : '.')}#{name}"
      end

      def typify api_map
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map) || typify_from_super(api_map)
        return type.qualify(api_map, namespace) unless type.nil?
        name.end_with?('?') ? ComplexType::BOOLEAN : ComplexType::UNDEFINED
      end

      # @return [Array<Pin::Parameter>]
      def parameters
        @parameters ||= []
      end

      # @return [Array<String>]
      def parameter_names
        parameters.map(&:name)
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
          @documentation += "\n\n" unless @documentation.empty?
          @documentation += "Visibility: #{visibility}"
        end
        @documentation.to_s
      end

      def explicit?
        @explicit
      end

      private

      # @return [ComplexType]
      def generate_complex_type
        tags = docstring.tags(:return).map(&:types).flatten.reject(&:nil?)
        return ComplexType::UNDEFINED if tags.empty?
        ComplexType.try_parse *tags
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
          result = resolve_reference(ref.owner.to_s, api_map)
          return result unless result.nil?
        end
        match = comments.match(/^[ \t]*\(see (.*)\)/m)
        return nil if match.nil?
        resolve_reference match[1], api_map
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def typify_from_super api_map
        stack = api_map.get_method_stack(namespace, name, scope: scope).reject { |pin| pin.path == path }
        return nil if stack.empty?
        stack.each do |pin|
          return pin.return_type unless pin.return_type.undefined?
        end
        nil
      end

      # @param ref [String]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def resolve_reference ref, api_map
        parts = ref.split(/[\.#]/)
        if parts.first.empty? || parts.one?
          path = "#{namespace}#{ref}"
        else
          fqns = api_map.qualify(parts.first, namespace)
          return ComplexType::UNDEFINED if fqns.nil?
          path = fqns + ref[parts.first.length] + parts.last
        end
        pins = api_map.get_path_pins(path)
        pins.each do |pin|
          type = pin.typify(api_map)
          return type unless type.undefined?
        end
        nil
      end
    end
  end
end
