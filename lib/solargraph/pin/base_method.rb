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
          Solargraph::Logging.logger.warn e.message
          ComplexType::UNDEFINED
        end
      end

      # @param [ApiMap]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
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
            type = pin.typify(api_map)
            return type unless type.undefined?
          end
        end
        nil
      end
    end
  end
end
