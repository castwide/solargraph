# frozen_string_literal: true

require 'set'

module Solargraph
  class ApiMap
    class Store
      # @return [Array<Solargraph::Pin::Base>]
      attr_reader :pins

      # @param pins [Array<Solargraph::Pin::Base>]
      def initialize pins = []
        @pins = pins
        index
      end

      # @param fqns [String]
      # @param visibility [Array<Symbol>]
      # @return [Array<Solargraph::Pin::Base>]
      def get_constants fqns, visibility = [:public]
        namespace_children(fqns).select { |pin|
          !pin.name.empty? && (pin.is_a?(Pin::Namespace) || pin.is_a?(Pin::Constant)) && visibility.include?(pin.visibility)
        }
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @param visibility [Array<Symbol>]
      # @return [Array<Solargraph::Pin::Base>]
      def get_methods fqns, scope: :instance, visibility: [:public]
        namespace_children(fqns).select do |pin|
          pin.is_a?(Pin::BaseMethod) && pin.scope == scope && visibility.include?(pin.visibility)
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
      # @return [Array<Solargraph::Pin::Base>]
      def get_instance_variables(fqns, scope = :instance)
        all_instance_variables.select { |pin|
          pin.binder.namespace == fqns && pin.binder.scope == scope
        }
      end

      # @param fqns [String]
      # @return [Array<Solargraph::Pin::Base>]
      def get_class_variables(fqns)
        namespace_children(fqns).select{|pin| pin.is_a?(Pin::ClassVariable)}
      end

      # @return [Array<Solargraph::Pin::Base>]
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

      # @return [Array<Solargraph::Pin::Base>]
      def namespace_pins
        pins_by_class(Solargraph::Pin::Namespace)
      end

      # @return [Array<Solargraph::Pin::BaseMethod>]
      def method_pins
        pins_by_class(Solargraph::Pin::BaseMethod)
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

      # @return [Hash]
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

      # @return [Array<Pin::Block>]
      def block_pins
        pins_by_class(Pin::Block)
      end

      def inspect
        # Avoid insane dumps in specs
        to_s
      end

      # @param klass [Class]
      # @return [Array<Solargraph::Pin::Base>]
      def pins_by_class klass
        @pin_select_cache[klass] ||= @pin_class_hash.filter { |key, _| key <= klass }.values.flatten
      end

      private

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

      def fqns_pins_map
        @fqns_pins_map ||= Hash.new do |h, (base, name)|
          value = namespace_children(base).select { |pin| pin.name == name && pin.is_a?(Pin::Namespace) }
          h[[base, name]] = value
        end
      end

      # @return [Array<Solargraph::Pin::Symbol>]
      def symbols
        pins_by_class(Pin::Symbol)
      end

      def superclass_references
        @superclass_references ||= {}
      end

      def include_references
        @include_references ||= {}
      end

      def prepend_references
        @prepend_references ||= {}
      end

      def extend_references
        @extend_references ||= {}
      end

      # @param name [String]
      # @return [Array<Solargraph::Pin::Base>]
      def namespace_children name
        namespace_map[name] || []
      end

      # @return [Hash]
      def namespace_map
        @namespace_map ||= {}
      end

      def all_instance_variables
        pins_by_class(Pin::InstanceVariable)
      end

      def path_pin_hash
        @path_pin_hash ||= {}
      end

      # @return [void]
      def index
        set = pins.to_set
        @pin_class_hash = set.classify(&:class).transform_values(&:to_a)
        @pin_select_cache = {}
        @namespace_map = set.classify(&:namespace).transform_values(&:to_a)
        @path_pin_hash = set.classify(&:path).transform_values(&:to_a)
        @namespaces = @path_pin_hash.keys.compact
        pins_by_class(Pin::Reference::Include).each do |pin|
          include_references[pin.namespace] ||= []
          include_references[pin.namespace].push pin.name
        end
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
          (ovr.tags.map(&:tag_name) + ovr.delete).uniq.each do |tag|
            pin.docstring.delete_tags tag.to_sym
          end
          ovr.tags.each do |tag|
            pin.docstring.add_tag(tag)
          end
        end
        # @todo This is probably not the best place for these overrides
        superclass_references['Integer'] = ['Numeric']
        superclass_references['Float'] = ['Numeric']
        superclass_references['File'] = ['IO']
      end
    end
  end
end
