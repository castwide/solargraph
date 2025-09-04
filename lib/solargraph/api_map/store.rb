# frozen_string_literal: true

module Solargraph
  class ApiMap
    # Queryable collection of Pins representing a Workspace, gems and the Ruby
    # core.
    #
    class Store
      # @param pinsets [Array<Enumerable<Pin::Base>>]
      def initialize *pinsets
        @pinsets = pinsets
        catalog pinsets
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        index.pins
      end

      # @param pinsets [Array<Enumerable<Pin::Base>>]
      # @return [Boolean] True if the index was updated
      def update *pinsets
        return catalog(pinsets) if pinsets.length != @pinsets.length

        changed = pinsets.find_index.with_index { |pinset, idx| @pinsets[idx] != pinset }
        return false unless changed

        # @todo Fix this map
        @fqns_pins_map = nil
        return catalog(pinsets) if changed == 0

        pinsets[changed..].each_with_index do |pins, idx|
          @pinsets[changed + idx] = pins
          @indexes[changed + idx] = if pins.empty?
            @indexes[changed + idx - 1]
          else
            @indexes[changed + idx - 1].merge(pins)
          end
        end
        true
      end

      def to_s
        self.class.to_s
      end

      def inspect
        to_s
      end

      # @param fqns [String]
      # @param visibility [Array<Symbol>]
      # @return [Enumerable<Solargraph::Pin::Namespace, Solargraph::Pin::Constant>]
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
        all_pins = namespace_children(fqns).select do |pin|
          pin.is_a?(Pin::Method) && pin.scope == scope && visibility.include?(pin.visibility)
        end
        GemPins.combine_method_pins_by_path(all_pins)
      end

      # @param fq_tag [String]
      # @return [String, nil]
      def get_superclass fq_tag
        raise "Do not prefix fully qualified tags with '::' - #{fq_tag.inspect}" if fq_tag.start_with?('::')
        sub = ComplexType.try_parse(fq_tag)
        return nil if sub.nil?
        return sub.simplify_literals.name if sub.literal?
        return 'Boolean' if %w[TrueClass FalseClass].include?(fq_tag)
        fqns = sub.namespace
        return superclass_references[fq_tag].first if superclass_references.key?(fq_tag)
        return superclass_references[fqns].first if superclass_references.key?(fqns)
        return 'Object' if fqns != 'BasicObject' && namespace_exists?(fqns)
        return 'Object' if fqns == 'Boolean'
        simplified_literal_name = ComplexType.parse("#{fqns}").simplify_literals.name
        return simplified_literal_name if simplified_literal_name != fqns
        nil
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_includes fqns
        include_references[fqns] || []
      end

      # @param fqns [String]
      # @return [Array<Pin::Reference::Include>]
      def get_include_pins fqns
        include_reference_pins[fqns] || []
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
        index.path_pin_hash[path]
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
      #
      # @return [Enumerable<Solargraph::Pin::ClassVariable>]
      def get_class_variables(fqns)
        namespace_children(fqns).select { |pin| pin.is_a?(Pin::ClassVariable)}
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

      # @return [Enumerable<Solargraph::Pin::Namespace>]
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

      # @generic T
      # @param klass [Class<generic<T>>]
      # @return [Set<generic<T>>]
      def pins_by_class klass
        index.pins_by_class klass
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

      # Get all ancestors (superclasses, includes, prepends, extends) for a namespace
      # @param fqns [String] The fully qualified namespace
      # @return [Array<String>] Array of ancestor namespaces including the original
      def get_ancestors(fqns)
        return [] if fqns.nil? || fqns.empty?

        ancestors = [fqns]
        visited = Set.new
        queue = [fqns]

        until queue.empty?
          current = queue.shift
          next if current.nil? || current.empty? || visited.include?(current)
          visited.add(current)

          current = current.gsub(/^::/, '')

          # Add superclass
          superclass = get_superclass(current)
          if superclass && !superclass.empty? && !visited.include?(superclass)
            ancestors << superclass
            queue << superclass
          end

          # Add includes, prepends, and extends
          [get_includes(current), get_prepends(current), get_extends(current)].each do |refs|
            next if refs.nil?
            refs.each do |ref|
              next if ref.nil? || ref.empty? || visited.include?(ref)
              ancestors << ref
              queue << ref
            end
          end
        end

        ancestors.compact.uniq
      end

      private

      # @return [Index]
      def index
        @indexes.last
      end

      # @param pinsets [Array<Enumerable<Pin::Base>>]
      #
      # @return [void]
      def catalog pinsets
        @pinsets = pinsets
        # @type [Array<Index>]
        @indexes = []
        pinsets.each do |pins|
          if @indexes.last && pins.empty?
            @indexes.push @indexes.last
          else
            @indexes.push(@indexes.last&.merge(pins) || Solargraph::ApiMap::Index.new(pins))
          end
        end
        true
      end

      # @return [Hash{::Array(String, String) => ::Array<Pin::Namespace>}]
      def fqns_pins_map
        @fqns_pins_map ||= Hash.new do |h, (base, name)|
          value = namespace_children(base).select { |pin| pin.name == name && pin.is_a?(Pin::Namespace) }
          h[[base, name]] = value
        end
      end

      # @return [Enumerable<Solargraph::Pin::Symbol>]
      def symbols
        index.pins_by_class(Pin::Symbol)
      end

      # @return [Hash{String => Array<String>}]
      def superclass_references
        index.superclass_references
      end

      # @return [Hash{String => Array<Pin::Reference::Include>}]
      def include_references
        index.include_references
      end

      # @return [Hash{String => Array<Solargraph::Pin::Reference::Include>}]
      def include_reference_pins
        index.include_reference_pins
      end

      # @return [Hash{String => Array<Pin::Reference::Prepend>}]
      def prepend_references
        index.prepend_references
      end

      # @return [Hash{String => Array<Pin::Reference::Extend>}]
      def extend_references
        index.extend_references
      end

      # @param name [String]
      # @return [Enumerable<Solargraph::Pin::Base>]
      def namespace_children name
        return [] unless index.namespace_hash.key?(name)
        index.namespace_hash[name]
      end

      # @return [Enumerable<Pin::InstanceVariable>]
      def all_instance_variables
        index.pins_by_class(Pin::InstanceVariable)
      end
    end
  end
end
