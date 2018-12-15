module Solargraph
  module Pin
    class BaseMethod < Base
      # @return [Symbol] :instance or :class
      attr_reader :scope

      # @return [Symbol] :public, :private, or :protected
      attr_reader :visibility

      def return_complex_type
        @return_complex_type ||= generate_complex_type
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
