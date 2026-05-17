# frozen_string_literal: true

module Solargraph
  class YardMap
    class Macro
      PROCESSABLE_DIRECTIVES = %w[method attribute parse].freeze

      class << self
        # @param directive [YARD::Tags::Directive]
        # @param method_pin [Pin::Method]
        # @return [Macro]
        def from_directive directive, method_pin
          macro_name = directive.tag.name.empty? ? method_pin.path.downcase : directive.tag.name
          method_object = method_object_from_pin(method_pin)
          code = directive.tag.text.to_s.gsub(/\n(?!@!|\s)/, "\n  ")
          macro_object = YARD::CodeObjects::MacroObject.create(macro_name.to_s, code, method_object)
          new(macro_object, method_pin, directive)
        end

        private

        # @param method_pin [Pin::Method]
        # @return [YARD::CodeObjects::MethodObject]
        def method_object_from_pin method_pin
          namespace_object = nil
          method_pin.each_closure do |namespace_pin|
            next if namespace_pin.name.empty?

            namespace_object = YARD::CodeObjects::NamespaceObject.new(
              namespace_object,
              namespace_pin.name.to_sym
            )
          end
          # @sg-ignore Wrong argument type for YARD::CodeObjects::MethodObject.new: namespace
          # expected YARD::CodeObjects::NamespaceObject, got nil.
          #   False positive because namespace_object is set in the loop above.
          YARD::CodeObjects::MethodObject.new(namespace_object, method_pin.name)
        end
      end

      # @return [YARD::Tags::MacroDirective]
      attr_reader :directive
      # @return [YARD::CodeObjects::MacroObject]
      attr_reader :macro_object

      # @param macro_object [YARD::CodeObjects::MacroObject]
      # @param method_pin [Pin::Method]
      # @param directive [YARD::Tags::Directive]
      def initialize macro_object, method_pin, directive
        @macro_object = macro_object
        @method_pin = method_pin
        @directive = directive
      end

      # @return [String]
      def name
        @directive.tag.name.to_s
      end

      # @return [String]
      def text
        @directive.tag.text.to_s
      end

      # @return [YARD::Tags::Tag]
      def tag
        @directive.tag
      end

      # @param chain [Source::Chain]
      # @param pin [Pin::Closure]
      # @param source_map [SourceMap]
      def generate_pins_from chain, pin, source_map
        call_location = Solargraph::Location.from_node(chain.node)
        generate_yardoc_from(chain, source_map).reduce([]) do |generated_pins, directive|
          directive_processor = YardMap::Directives.for(directive)
          next generated_pins unless directive_processor && call_location
          generated_pins + directive_processor.process_directive(
            source_map.source, source_map.pins, call_location.range.start, call_location.range.start, directive
          )
        end
      end

      private

      # @param chain [Solargraph::Source::Chain]
      def generate_yardoc_from chain, source_map
        name = chain.links.last.word
        values = chain.links.last.arguments.map(&:node).map { |arg| Solargraph::Parser::ParserGem::NodeMethods.simple_convert(arg).to_s }
        code = source_map.source.code_for(chain.node)
        expanded_comment = macro_object.expand([name, *values], source_map.source.code_for(chain.node))
                                       .gsub(/\n(?!@!|\s)/, "\n  ")
        directives = Solargraph::Source.parse_docstring(expanded_comment).directives.select do |directive|
          PROCESSABLE_DIRECTIVES.include?(directive.tag.tag_name)
        end
        directives.each do |directive|
          comments = source_map.source.comments_for(chain.node)
          if comments&.length&.positive? && directive.tag.tag_name != 'parse'
            directive.tag.text += "\n#{comments}"
          end
        end
        directives
      end
    end
  end
end
