# frozen_string_literal: true

module Solargraph
  class ApiMap
    class Index
      # @param pins [Array<Pin::Base>]
      def initialize pins
        catalog pins
      end

      # @return [Array<Pin::Base>]
      def pins
        @pins ||= []
      end

      def namespace_hash
        @namespace_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      def pin_class_hash
        @pin_class_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      def path_pin_hash
        @path_pin_hash ||= Hash.new { |h, k| h[k] = [] }
      end

      # @generic T
      # @param klass [Class<generic<T>>]
      # @return [Set<generic<T>>]
      def pins_by_class klass
        # @type [Set<Solargraph::Pin::Base>]
        s = Set.new
        @pin_select_cache[klass] ||= pin_class_hash.each_with_object(s) { |(key, o), n| n.merge(o) if key <= klass }
      end

      def include_references
        @include_references ||= Hash.new { |h, k| h[k] = [] }
      end

      def extend_references
        @extend_references ||= Hash.new { |h, k| h[k] = [] }
      end

      def prepend_references
        @prepend_references ||= Hash.new { |h, k| h[k] = [] }
      end

      def superclass_references
        @superclass_references ||= Hash.new { |h, k| h[k] = [] }
      end

      def merge pins
        deep_clone.catalog pins
      end

      protected

      attr_writer :pins, :pin_select_cache, :namespace_hash, :pin_class_hash, :path_pin_hash, :include_references,
                  :extend_references, :prepend_references, :superclass_references

      def deep_clone
        Index.allocate.tap do |copy|
          copy.pin_select_cache = {}
          copy.pins = pins.clone
          %i[
            namespace_hash pin_class_hash path_pin_hash include_references extend_references prepend_references
            superclass_references
          ].each do |sym|
            copy.send("#{sym}=", send(sym).clone)
            copy.send(sym)&.transform_values!(&:clone)
          end
        end
      end

      def catalog new_pins
        @pin_select_cache = {}
        pins.concat new_pins
        set = new_pins.to_set
        set.classify(&:class)
           .map { |k, v| pin_class_hash[k].concat v.to_a }
        set.classify(&:namespace)
           .map { |k, v| namespace_hash[k].concat v.to_a }
        set.classify(&:path)
           .map { |k, v| path_pin_hash[k].concat v.to_a }
        @namespaces = path_pin_hash.keys.compact.to_set
        pins_by_class(Pin::Reference::Include).each do |pin|
          store_parametric_reference(include_references, pin)
        end
        # @todo move the rest of these reference pins over to use
        #   generic types, adding rbs_map/conversions.rb code to
        #   populate type parameters and adding related specs ensuring
        #   the generics get resolved, along with any api_map.rb
        #   changes needed in
        pins_by_class(Pin::Reference::Prepend).each do |pin|
          prepend_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Extend).each do |pin|
          extend_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Superclass).each do |pin|
          superclass_references[pin.namespace].push pin.name
        end
        pins_by_class(Pin::Reference::Override).each do |ovr|
          pin = path_pin_hash[ovr.name].first
          next if pin.nil?
          new_pin = if pin.path.end_with?('#initialize')
            path_pin_hash[pin.path.sub(/#initialize/, '.new')].first
          end
          (ovr.tags.map(&:tag_name) + ovr.delete).uniq.each do |tag|
            pin.docstring.delete_tags tag
            new_pin.docstring.delete_tags tag if new_pin
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
        self
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
        h[referencing_ns].push referenced_tag
      end

      # @param pin [Pin::Method]
      # @param tag [YARD::Tags::Tag]
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
