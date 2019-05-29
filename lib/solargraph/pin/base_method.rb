module Solargraph
  module Pin
    # The base class for method and attribute pins.
    #
    class BaseMethod < Closure
      # @return [Symbol] :public, :private, or :protected
      attr_reader :visibility

      def return_type
        @return_type ||= generate_complex_type
      end

      def path
        @path ||= namespace.to_s + (scope == :instance ? '#' : '.') + name.to_s
      end

      def typify api_map
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map)
        return type unless type.nil?
        ComplexType::UNDEFINED
      end

      def parameters
        []
      end

      def parameter_names
        []
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
        ComplexType.try_parse *tag.types
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
          result = resolve_reference(ref.owner.to_s, api_map)
          return result unless result.nil?
        end
        match = comments.match(/\(see (.*)\)/)
        return nil if match.nil?
        resolve_reference match[1], api_map
      end

      # @param ref [String]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def resolve_reference ref, api_map
        parts = ref.split(/[\.#]/)
        if parts.first.empty?
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
