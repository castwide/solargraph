# frozen_string_literal: true

module Solargraph
  module Convention
    class ActiveSupportConcern < Base
      include Logging

      # @return [Array<Pin::Base>]
      attr_reader :pins

      def object(api_map, rooted_tag, scope, visibility, deep, skip, no_core)
        environ = Environ.new
        return environ unless scope == :class

        rooted_type = ComplexType.parse(rooted_tag).force_rooted
        fqns = rooted_type.namespace
        namespace_pin = api_map.get_path_pins(fqns).select { |p| p.is_a?(Pin::Namespace) }.first

        api_map.get_includes(fqns).reverse.each do |include_tag|
          rooted_include_tag = api_map.qualify(include_tag, rooted_tag)
          next if rooted_include_tag.nil?
          logger.debug { "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - Handling class include include_tag=#{include_tag}" }
          module_extends = api_map.get_extends(rooted_include_tag)
          logger.debug { "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - found module extends of #{rooted_include_tag}: #{module_extends}" }
          # ActiveSupport::Concern is syntactic sugar for a common
          # pattern to include class methods while mixing-in a Module
          # See https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
          if module_extends.include? 'ActiveSupport::Concern'
            # yard-activesupport-concern pulls methods inside
            # 'class_methods' blocks into main class visible from YARD
            included_class_pins = api_map.inner_get_methods_from_reference(rooted_include_tag, namespace_pin, rooted_type,
                                                                           :class, visibility, deep, skip, true)
            logger.debug { "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - Found #{included_class_pins.length} inluded class methods for #{rooted_include_tag}" }

            environ.pins.concat included_class_pins
            # another pattern is to put class methods inside a submodule
            classmethods_include_tag = rooted_include_tag + "::ClassMethods"
            included_classmethods_pins = api_map.inner_get_methods_from_reference(classmethods_include_tag, namespace_pin, rooted_type, :instance, visibility, deep, skip, true)
            logger.debug { "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - Found #{included_classmethods_pins.length} included classmethod class methods for #{classmethods_include_tag}" }
            environ.pins.concat included_classmethods_pins
          end
        end

        environ
      end

      def global(doc_map)
        Environ.new(yard_plugins: ['activesupport-concern'])
      end
    end
  end
end
