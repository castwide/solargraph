# frozen_string_literal: true

module Solargraph
  module Convention
    # ActiveSupport::Concern is syntactic sugar for a common
    # pattern to include class methods while mixing-in a Module
    # See https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
    class ActiveSupportConcern < Base
      include Logging

      # @return [Array<Pin::Base>]
      attr_reader :pins

      # @param api_map [ApiMap]
      # @param rooted_tag [String]
      # @param scope [Symbol] :class or :instance
      # @param visibility [Array<Symbol>] :public, :protected, and/or :private
      # @param deep [Boolean] whether to include methods from included modules
      # @param skip [Set<String>]
      # @param _no_core [Boolean]n whether to skip core methods
      def object api_map, rooted_tag, scope, visibility, deep, skip, _no_core
        moo = ObjectProcessor.new(api_map, rooted_tag, scope, visibility, deep, skip)
        moo.environ
      end

      # yard-activesupport-concern pulls methods inside
      # 'class_methods' blocks into main class visible from YARD
      #
      # @param _doc_map [DocMap]
      def global _doc_map
        Environ.new(yard_plugins: ['activesupport-concern'])
      end

      # Process an object to add any class methods brought in via
      # ActiveSupport::Concern
      class ObjectProcessor
        include Logging

        attr_reader :environ

        # @param api_map [ApiMap]
        # @param rooted_tag [String] the tag of the class or module being processed
        # @param scope [Symbol] :class or :instance
        # @param visibility [Array<Symbol>] :public, :protected, and/or :private
        # @param deep [Boolean] whether to include methods from included modules
        # @param skip [Set<String>] a set of tags to skip
        def initialize api_map, rooted_tag, scope, visibility, deep, skip
          @api_map = api_map
          @rooted_tag = rooted_tag
          @scope = scope
          @visibility = visibility
          @deep = deep
          @skip = skip

          @environ = Environ.new
          return unless scope == :class

          @rooted_type = ComplexType.parse(rooted_tag).force_rooted
          @fqns = rooted_type.namespace
          @namespace_pin = api_map.get_path_pins(fqns).select { |p| p.is_a?(Pin::Namespace) }.first

          api_map.get_includes(fqns).reverse.each do |include_tag|
            process_include include_tag
          end
        end

        private

        attr_reader :api_map, :rooted_tag, :rooted_type, :scope,
                    :visibility, :deep, :skip, :namespace_pin,
                    :fqns

        # @param include_tag [Pin::Reference::Include] the include reference pin
        #
        # @return [void]
        def process_include include_tag
          rooted_include_tag = api_map.dereference(include_tag)
          return if rooted_include_tag.nil?
          logger.debug do
            "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - " \
              "Handling class include include_tag=#{include_tag}"
          end
          module_extends = api_map.get_extends(rooted_include_tag).map(&:parametrized_tag).map(&:to_s)
          logger.debug do
            "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - " \
              "found module extends of #{rooted_include_tag}: #{module_extends}"
          end
          return unless module_extends.include? 'ActiveSupport::Concern'
          included_class_pins = api_map.inner_get_methods_from_reference(rooted_include_tag, namespace_pin, rooted_type,
                                                                         :class, visibility, deep, skip, true)
          logger.debug do
            "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - " \
              "Found #{included_class_pins.length} inluded class methods for #{rooted_include_tag}"
          end
          environ.pins.concat included_class_pins
          # another pattern is to put class methods inside a submodule
          classmethods_include_tag = "#{rooted_include_tag}::ClassMethods"
          included_classmethods_pins =
            api_map.inner_get_methods_from_reference(classmethods_include_tag, namespace_pin, rooted_type,
                                                     :instance, visibility, deep, skip, true)
          logger.debug do
            "ActiveSupportConcern#object(#{fqns}, #{scope}, #{visibility}, #{deep}) - " \
              "Found #{included_classmethods_pins.length} included classmethod " \
              "class methods for #{classmethods_include_tag}"
          end
          environ.pins.concat included_classmethods_pins
        end
      end
    end
  end
end
