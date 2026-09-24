# frozen_string_literal: true

module Solargraph
  class ApiMap
    class Index
      include Logging

      # @return [Set<String>]
      attr_reader :macro_method_names

      # @return [Hash{String => Set<Pin::Method>}]
      attr_reader :macro_method_name_pins

      # @param pins [Array<Pin::Base>]
      def initialize pins = []
        catalog pins
      end

      # @return [Array<Pin::Base>]
      def pins
        @pins ||= []
      end

      # @return [Hash{String => Array<Pin::Namespace>}]
      def namespace_hash
        # @param h [String]
        # @param k [Array<Pin::Namespace>]
        @namespace_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Base>}]
      def pin_class_hash
        # @param h [String]
        # @param k [Array<Pin::Base>]
        @pin_class_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Base>}]
      def path_pin_hash
        # @param h [String]
        # @param k [Array<Pin::Base>]
        @path_pin_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => ComplexType}]
      def alias_hash
        @alias_hash ||= {}
      end

      # @generic T
      # @param klass [Class<generic<T>>]
      # @return [Set<generic<T>>]
      def pins_by_class klass
        # @type [Set<generic<T>>]
        s = Set.new
        # @sg-ignore need to support destructured args in blocks
        @pin_select_cache[klass] ||= pin_class_hash.each_with_object(s) { |(key, o), n| n.merge(o) if key <= klass }
      end

      # @return [Hash{String => Array<Pin::Reference::Include>}]
      def include_references
        # @param h [String]
        # @param k [Array<String>]
        @include_references ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Reference::Include>}]
      def include_reference_pins
        # @param h [String]
        # @param k [Array<Pin::Reference::Include>]
        @include_reference_pins ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Reference::Extend>}]
      def extend_references
        # @param h [String]
        # @param k [Array<String>]
        @extend_references ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Reference::Prepend>}]
      def prepend_references
        # @param h [String]
        # @param k [Array<String>]
        @prepend_references ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Hash{String => Array<Pin::Reference::Superclass>}]
      def superclass_references
        # @param h [String]
        # @param k [Array<String>]
        @superclass_references ||= Hash.new { |h, k| h[k] = [] }
      end

      # @param pins [Enumerable<Pin::Base>]
      # @return [self]
      def merge pins
        deep_clone.catalog pins
      end

      protected

      attr_writer :pins, :pin_select_cache, :namespace_hash, :pin_class_hash, :path_pin_hash, :include_references,
                  :extend_references, :prepend_references, :superclass_references, :macro_method_names,
                  :macro_method_name_pins

      # @return [self]
      def deep_clone
        Index.allocate.tap do |copy|
          copy.pin_select_cache = {}
          copy.pins = pins.clone
          copy.macro_method_names = macro_method_names
          %i[
            namespace_hash pin_class_hash path_pin_hash include_references extend_references prepend_references
            superclass_references macro_method_name_pins
          ].each do |sym|
            copy.send("#{sym}=", send(sym).clone)
            copy.send(sym)&.transform_values!(&:clone)
          end
        end
      end

      # @param new_pins [Enumerable<Pin::Base>]
      #
      # @return [self]
      def catalog new_pins
        # @type [Hash{Class<generic<T>> => Set<generic<T>>}]
        @pin_select_cache = {}
        pins.concat new_pins
        set = new_pins.to_set
        # @param k [String]
        # @param v [Set<Pin::Base>]
        set.classify(&:class)
           .map { |k, v| pin_class_hash[k].concat v.to_a }
        # @param k [String]
        # @param v [Set<Pin::Namespace>]
        set.classify(&:namespace)
           .map { |k, v| namespace_hash[k].concat v.to_a }
        # @param k [String]
        # @param v [Set<Pin::Base>]
        set.classify(&:path)
           .map { |k, v| path_pin_hash[k].concat v.to_a }
        @namespaces = path_pin_hash.keys.compact.to_set
        map_references Pin::Reference::Include, include_references
        map_references Pin::Reference::Prepend, prepend_references
        map_references Pin::Reference::Extend, extend_references
        map_references Pin::Reference::Superclass, superclass_references
        macro_pins = pins_by_class(Pin::Method).select { |pin| pin.macros.any? }
        @macro_method_names = macro_pins.to_set(&:name)
        @macro_method_name_pins = macro_pins.to_set.classify(&:name)
        map_overrides
        pins_by_class(Pin::Reference::TypeAlias).each { |pin| alias_hash[pin.name] = pin.return_type }
        self
      end

      # @generic T
      # @param klass [Class<generic<T>>]
      # @param hash [Hash{String => Array<generic<T>>}]
      #
      # @return [void]
      def map_references klass, hash
        # @param pin [generic<T>]
        pins_by_class(klass).each do |pin|
          hash[pin.namespace].push pin
        end
      end

      # @return [void]
      def map_overrides
        pins_by_class(Pin::Reference::Override).each do |ovr|
          # Iterate a copy: applying an override rewrites this array.
          (path_pin_hash[ovr.name] || []).dup.each do |pin|
            new_pin = ((path_pin_hash[pin.path.sub('#initialize', '.new')] || []).first if pin.path.end_with?('#initialize'))
            apply_override pin, ovr
            apply_override new_pin, ovr if new_pin
          end
        end
      end

      # Join the override onto the pin as the higher-authority side and swap
      # the result in, rather than mutating a pin other structures still hold.
      #
      # @param pin [Pin::Base]
      # @param ovr [Pin::Reference::Override]
      # @return [void]
      def apply_override pin, ovr
        combined = pin.combine_with(override_pin_for(pin, ovr))
        # combined belongs to us alone, so deleting from it touches nothing shared.
        ovr.delete.each { |name| combined.docstring.delete_tags(name.to_s) }
        ovr.tags.each { |tag| redefine_return_type combined, tag }
        rebind_parameters combined
        combined.reset_generated!
        replace_pin pin, combined
      end

      # A Parameter reads its type from its closure's docstring, so the
      # combined pin needs copies pointing at itself; the originals still
      # point at the pin it replaces, which no longer carries the override.
      #
      # @param pin [Pin::Base]
      # @return [void]
      def rebind_parameters pin
        return nil unless pin.is_a?(Pin::Method)

        pin.parameters = rebound_parameters(pin, pin.parameters)
        pin.signatures.each { |sig| sig.parameters = rebound_parameters(pin, sig.parameters) }
        nil
      end

      # @param closure [Pin::Base]
      # @param parameters [::Array<Pin::Parameter>]
      # @return [::Array<Pin::Parameter>]
      def rebound_parameters closure, parameters
        parameters.map do |param|
          rebound = param.dup
          rebound.closure = closure
          rebound
        end
      end

      # A pin carrying only what the override says, ranked above the pin it
      # targets so its tags win the combine.
      #
      # @param pin [Pin::Base]
      # @param ovr [Pin::Reference::Override]
      # @return [Pin::Base]
      def override_pin_for pin, ovr
        docstring = YARD::Docstring.new('')
        ovr.tags.each { |tag| docstring.add_tag(tag) }
        attrs = { name: pin.name, closure: pin.closure, docstring: docstring,
                  combine_priority: 1, source: :override }
        if pin.is_a?(Pin::Method)
          attrs[:scope] = pin.scope
          # Without these, choose picks the empty array as the lesser of the two
          # and the combined pin loses its parameters.
          attrs[:parameters] = pin.parameters
        end
        pin.class.new(**attrs)
      end

      # macro_method_name_pins is built before overrides are applied, and
      # process_macros matches against it by pin equality. A replaced pin left
      # here stops matching, and its @!macro directives stop expanding.
      #
      # @param old_pin [Pin::Base]
      # @param new_pin [Pin::Base]
      # @return [void]
      def swap_macro_pin old_pin, new_pin
        pin_set = macro_method_name_pins[old_pin.name]
        return nil if pin_set.nil?
        return nil unless pin_set.include?(old_pin)

        pin_set.delete old_pin
        pin_set.add new_pin
        nil
      end

      # @param collection [::Array<Pin::Base>, nil]
      # @param old_pin [Pin::Base]
      # @param new_pin [Pin::Base]
      # @return [void]
      def swap_pin collection, old_pin, new_pin
        return nil if collection.nil?

        collection.map! { |pin| pin.equal?(old_pin) ? new_pin : pin }
        nil
      end

      # @param old_pin [Pin::Base]
      # @param new_pin [Pin::Base]
      # @return [void]
      def replace_pin old_pin, new_pin
        swap_macro_pin old_pin, new_pin
        swap_pin pins, old_pin, new_pin
        swap_pin namespace_hash[old_pin.namespace], old_pin, new_pin
        swap_pin pin_class_hash[old_pin.class], old_pin, new_pin
        swap_pin path_pin_hash[old_pin.path], old_pin, new_pin
        # Rebuilt lazily from pin_class_hash, which just changed.
        @pin_select_cache.clear
        nil
      end

      # @param pin [Pin::Method, nil]
      # @param tag [YARD::Tags::Tag]
      # @return [void]
      def redefine_return_type pin, tag
        # @todo can this be made to not mutate existing pins and use
        #   proxy() / proxy_with_signatures() instead?
        return unless pin && tag.tag_name == 'return'
        pin.instance_variable_set(:@return_type, ComplexType.try_parse(tag.type))
        pin.signatures.each do |sig|
          sig.instance_variable_set(:@return_type, ComplexType.try_parse(tag.type))
        end
      end
    end
  end
end
