# frozen_string_literal: true

module Solargraph
  module YardMap
    class Macro
      PROCESSABLE_DIRECTIVES = %w[method attribute parse scope].freeze

      # Directives whose text is a value rather than a definition. The comments
      # attached to the macro's call site belong to the objects the macro
      # generates, but adding them to one of these directives would invalidate
      # its content.
      VALUE_DIRECTIVES = %w[parse scope].freeze

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
      # @return [Array<Pin::Base>]
      def generate_pins_from chain, pin, source_map
        call_location = Solargraph::Location.from_node(chain.node)
        return [] unless call_location

        # A @!scope directive in a macro applies to the objects the macro
        # generates after it, the same way it applies to the objects that
        # follow it in a namespace. Its effect ends with the macro.
        #
        # @type [::Symbol, nil]
        inherited_scope = nil

        # @param generated_pins [Array<Pin::Base>]
        generate_yardoc_from(chain, source_map).reduce([]) do |generated_pins, directive|
          # @sg-ignore flow sensitive typing confuses this block variable with the #directive attr reader
          if directive.tag.tag_name == 'scope'
            inherited_scope = Directives::ScopeDirective.parse_scope(directive) || inherited_scope
            next generated_pins
          end
          directive_processor = YardMap::Directives.for(directive)
          next generated_pins unless directive_processor
          new_pins = directive_processor.process_directive(
            source_map.source, source_map.pins, call_location.range.start, call_location.range.start, directive
          )
          if Directives::ScopeDirective.scopes_directive?(directive)
            # A @!scope directive nested in another directive's text applies
            # only to the object that directive defines.
            scope = Directives::ScopeDirective.nested_scope(directive) || inherited_scope
            Directives::ScopeDirective.apply_scope new_pins, scope
          end
          generated_pins + new_pins
        end
      end

      private

      # @param chain [Solargraph::Source::Chain]
      # @param [SourceMap] source_map
      # @return [Array<YARD::Tags::Directive>]
      def generate_yardoc_from chain, source_map
        # @sg-ignore Array#first/#last relies on non-empty invariant
        name = chain.links.last.word
        # @sg-ignore chain.links.last is assumed to be a Chain::Call
        values = chain.links.last.arguments.map(&:node).map { |arg| Solargraph::Parser::ParserGem::NodeMethods.simple_convert(arg).to_s }
        # @sg-ignore chain.node is assumed to exist
        code = source_map.source.code_for(chain.node)
        expanded_comment = macro_object.expand([name, *values], code)
                                       .gsub(/\n(?!@!|\s)/, "\n  ")
        directives = Solargraph::Source.parse_docstring(expanded_comment).directives.select do |directive|
          PROCESSABLE_DIRECTIVES.include?(directive.tag.tag_name)
        end
        directives.each do |directive|
          next if VALUE_DIRECTIVES.include? directive.tag.tag_name

          # @sg-ignore chain.node is assumed to exist
          comments = source_map.source.comments_for(chain.node)
          if comments&.length&.positive?
            directive.tag.text += "\n#{comments}"
          end
        end
        directives
      end
    end
  end
end
