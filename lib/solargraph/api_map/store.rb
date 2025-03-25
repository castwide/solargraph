# frozen_string_literal: true


module Solargraph
  class ApiMap
    class Store
      # @return [Array<Solargraph::Pin::Base>]
      attr_reader :pins

      # @param pins [Enumerable<Solargraph::Pin::Base>]
      def initialize pins = []
        @pins = pins
        index
      end

      # @param fqns [String]
      # @param visibility [Array<Symbol>]
      # @return [Enumerable<Solargraph::Pin::Base>]
      def get_constants fqns, visibility = [:public]
        namespace_children(fqns).select { |pin|
          !pin.name.empty? && (pin.is_a?(Pin::Namespace) || pin.is_a?(Pin::Constant)) && visibility.include?(pin.visibility)
        }
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @param visibility [Array<Symbol>]
      # @return [Enumerable<Solargraph::Pin::Method>]
      def get_methods fqns, scope: :instance, visibility: [:public]
        namespace_children(fqns).select do |pin|
          pin.is_a?(Pin::Method) && pin.scope == scope && visibility.include?(pin.visibility)
        end
      end

      # @param fqns [String]
      # @return [String, nil]
      def get_superclass fqns
        return superclass_references[fqns].first if superclass_references.key?(fqns)
        return 'Object' if fqns != 'BasicObject' && namespace_exists?(fqns)
        return 'Object' if fqns == 'Boolean'
        nil
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_includes fqns
        include_references[fqns] || []
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_prepends fqns
        prepend_references[fqns] || []
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_extends fqns
        extend_references[fqns] || []
      end

      # @param path [String]
      # @return [Array<Solargraph::Pin::Base>]
      def get_path_pins path
        path_pin_hash[path] || []
      end

      # @param fqns [String]
      # @param scope [Symbol] :class or :instance
      # @return [Enumerable<Solargraph::Pin::Base>]
      def get_instance_variables(fqns, scope = :instance)
        all_instance_variables.select { |pin|
          pin.binder.namespace == fqns && pin.binder.scope == scope
        }
      end

      # @param fqns [String]
      # @return [Enumerable<Solargraph::Pin::Base>]
      def get_class_variables(fqns)
        namespace_children(fqns).select{|pin| pin.is_a?(Pin::ClassVariable)}
      end

      # @return [Enumerable<Solargraph::Pin::Base>]
      def get_symbols
        symbols.uniq(&:name)
      end

      # @param fqns [String]
      # @return [Boolean]
      def namespace_exists?(fqns)
        fqns_pins(fqns).any?
      end

      # @return [Set<String>]
      def namespaces
        @namespaces ||= Set.new
      end

      # @return [Enumerable<Solargraph::Pin::Base>]
      def namespace_pins
        pins_by_class(Solargraph::Pin::Namespace)
      end

      # @return [Enumerable<Solargraph::Pin::Method>]
      def method_pins
        pins_by_class(Solargraph::Pin::Method)
      end

      # @param fqns [String]
      # @return [Array<String>]
      def domains(fqns)
        result = []
        fqns_pins(fqns).each do |nspin|
          result.concat nspin.domains
        end
        result
      end

      # @return [Hash{String => YARD::Tags::MacroDirective}]
      def named_macros
        @named_macros ||= begin
          result = {}
          pins.each do |pin|
            pin.macros.select{|m| m.tag.tag_name == 'macro' && !m.tag.text.empty? }.each do |macro|
              next if macro.tag.name.nil? || macro.tag.name.empty?
              result[macro.tag.name] = macro
            end
          end
          result
        end
      end

      # @return [Enumerable<Pin::Block>]
      def block_pins
        pins_by_class(Pin::Block)
      end

      def inspect
        # Avoid insane dumps in specs
        to_s
      end

      # @param klass [Class]
      # @return [Enumerable<Solargraph::Pin::Base>]
      def pins_by_class klass
        # @type [Set<Solargraph::Pin::Base>]
        s = Set.new
        @pin_select_cache[klass] ||= @pin_class_hash.each_with_object(s) { |(key, o), n| n.merge(o) if key <= klass }
      end

      # @param fqns [String]
      # @return [Array<Solargraph::Pin::Namespace>]
      def fqns_pins fqns
        return [] if fqns.nil?
        if fqns.include?('::')
          parts = fqns.split('::')
          name = parts.pop
          base = parts.join('::')
        else
          base = ''
          name = fqns
        end
        fqns_pins_map[[base, name]]
      end

      private

      # @return [Hash{Array(String, String) => Array<Pin::Namespace>}]
      def fqns_pins_map
        @fqns_pins_map ||= Hash.new do |h, (base, name)|
          value = namespace_children(base).select { |pin| pin.name == name && pin.is_a?(Pin::Namespace) }
          h[[base, name]] = value
        end
      end

      # @return [Enumerable<Solargraph::Pin::Symbol>]
      def symbols
        pins_by_class(Pin::Symbol)
      end

      # @return [Hash{String => Enumerable<String>}]
      def superclass_references
        @superclass_references ||= {}
      end

      # @return [Hash{String => Array<String>}]
      def include_references
        @include_references ||= {}
      end

      # @return [Hash{String => Array<String>}]
      def prepend_references
        @prepend_references ||= {}
      end

      # @return [Hash{String => Array<String>}]
      def extend_references
        @extend_references ||= {}
      end

      # @param name [String]
      # @return [Enumerable<Solargraph::Pin::Base>]
      def namespace_children name
        namespace_map[name] || []
      end

      # @return [Hash{String => Enumerable<Pin::Base>}
      def namespace_map
        @namespace_map ||= {}
      end

      # @return [Enumerable<Pin::InstanceVariable>]
      def all_instance_variables
        pins_by_class(Pin::InstanceVariable)
      end

      # @return [Hash{String => Array<Pin::Base>}]
      def path_pin_hash
        @path_pin_hash ||= {}
      end

      # Add references to a map
      #
      # @param h [Hash{String => Pin:Base}]
      # @param reference_pin [Pin::Reference]
      #
      # @return [void]
      def store_parametric_reference(h, reference_pin)
        referenced_ns = reference_pin.name
        referenced_tag_params = reference_pin.generic_values
        referenced_tag = referenced_ns +
                         if referenced_tag_params && referenced_tag_params.length > 0
                           "<" + referenced_tag_params.join(', ') + ">"
                         else
                           ''
                         end
        referencing_ns = reference_pin.namespace
        h[referencing_ns] ||= []
        h[referencing_ns].push referenced_tag
      end

      # @return [void]
      def index
        set = pins.to_set
        @pin_class_hash = set.classify(&:class).transform_values(&:to_a)
        # @type [Hash{Class => Enumerable<Solargraph::Pin::Base>}]
        @pin_select_cache = {}
        @namespace_map = set.classify(&:namespace)
        @path_pin_hash = set.classify(&:path)
        @namespaces = @path_pin_hash.keys.compact.to_set
        pins_by_class(Pin::Reference::Include).each do |pin|
          store_parametric_reference(include_references, pin)
        end
        # @todo move the rest of these reference pins over to use
        #   generic types, adding rbs_map/conversions.rb code to
        #   populate type parameters and adding related specs ensuring
        #   the generics get resolved, along with any api_map.rb
        #   changes needed in
        pins_by_class(Pin::Reference::Prepend).each do |pin|
          prepend_references[pin.namespace] ||= []
          prepend_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Extend).each do |pin|
          extend_references[pin.namespace] ||= []
          extend_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Superclass).each do |pin|
          superclass_references[pin.namespace] ||= []
          superclass_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Override).each do |ovr|
          pin = get_path_pins(ovr.name).first
          next if pin.nil?
          new_pin = if pin.path.end_with?('#initialize')
            get_path_pins(pin.path.sub(/#initialize/, '.new')).first
          end
          (ovr.tags.map(&:tag_name) + ovr.delete).uniq.each do |tag|
            pin.docstring.delete_tags tag.to_sym
            new_pin.docstring.delete_tags tag.to_sym if new_pin
          end
          ovr.tags.each do |tag|
            pin.docstring.add_tag(tag)
            redefine_return_type pin, tag
            if new_pin
              new_pin.docstring.add_tag(tag)
              redefine_return_type new_pin, tag
            end
          end
        end
      end

      # @param pin [Pin::Base]
      # @param tag [String]
      # @return [void]
      def redefine_return_type pin, tag
        return unless pin && tag.tag_name == 'return'
        pin.instance_variable_set(:@return_type, ComplexType.try_parse(tag.type))
        pin.signatures.each do |sig|
          sig.instance_variable_set(:@return_type, ComplexType.try_parse(tag.type))
        end
      end
    end
  end
end
