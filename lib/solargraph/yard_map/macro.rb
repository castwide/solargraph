# frozen_string_literal: true

module Solargraph
  class YardMap
    class Macro # rubocop:disable Style/Documentation
      PROCESSABLE_DIRECTIVES = %w[method attribute parse].freeze

      class << self
        # @param directive [YARD::Tags::Directive]
        # @param method_pin [Pin::Method]
        # @return [Macro]
        def from_directive(directive, method_pin)
          macro_name = directive.tag.name.empty? ? method_pin.path.downcase : directive.tag.name
          method_object = method_object_from_pin(method_pin)
          macro_object = YARD::CodeObjects::MacroObject.create(macro_name, directive.tag.text, method_object)
          new(macro_object, method_pin, directive)
        end

        private

        # @param method_pin [Pin::Method]
        # @return [YARD::CodeObjects::MethodObject]
        def method_object_from_pin(method_pin)
          namespace_object = nil
          method_pin.each_closure do |namespace_pin|
            next if namespace_pin.name.empty?

            namespace_object = YARD::CodeObjects::NamespaceObject.new(
              namespace_object,
              namespace_pin.name.to_sym
            )
          end
          YARD::CodeObjects::MethodObject.new(namespace_object, method_pin.name)
        end
      end

      # @return [YARD::Tags::MacroDirective]
      attr_reader :directive
      # @return [YARD::CodeObjects::MacroObject]
      attr_reader :macro_object

      # @param macro [YARD::MacroObject]
      # @param method_pin [Pin::Method]
      # @param directive [YARD::Tags::Directive]
      def initialize(macro_object, method_pin, directive)
        @macro_object = macro_object
        @method_pin = method_pin
        @directive = directive
      end

      # @return [String]
      def name
        @directive.tag.name
      end

      # @return [String]
      def text
        @directive.tag.text
      end

      # @return [YARD::Tags::Tag]
      def tag
        @directive.tag
      end

      # @param dsl_method_send [Pin::Ephemeral::ClassMethodSend]
      # @param source_map [SourceMap]
      # @return [Array<Pin::Base>]
      def generate_pins_from(dsl_method_send, source_map)
        call_location = dsl_method_send.location
        # @param directive [YARD::Tags::MethodDirective, YARD::Tags::AttributeDirective, YARD::Tags::ParseDirective]
        # @param generated_pins [Array<Pin::Base>]
        generate_yardoc_from(dsl_method_send).reduce([]) do |generated_pins, directive|
          directive_processor = YardMap::Directives.for(directive)
          next generated_pins unless directive_processor
          generated_pins + directive_processor.process_directive(
            source_map.source, source_map.pins, call_location.range.start, call_location.range.start, directive
          )
        end
      end

      private

      # @param method_call_pin [Pin::Ephemeral::ClassMethodSend]
      # @return [Array<YARD::Tags::MethodDirective>, Array<YARD::Tags::AttributeDirective>, Array<YARD::Tags::ParseDirective>]
      def generate_yardoc_from(class_method_send) # rubocop:disable Metrics/AbcSize
        expanded_comment = macro_object.expand([class_method_send.name, *class_method_send.argument_values],
                                               class_method_send.code)
        Solargraph::Source.parse_docstring(expanded_comment).directives.select do |directive|
          PROCESSABLE_DIRECTIVES.include?(directive.tag.tag_name)
        end.each do |directive|
          if class_method_send.comments.length.positive? && directive.tag.tag_name != 'parse'
            directive.tag.text += "\n#{class_method_send.comments}"
          end
        end
      end
    end
  end
end
