# frozen_string_literal: true

module Solargraph
  class ApiMap
    # Methods for handling constants.
    #
    class Constants
      # @param store [Store]
      def initialize store
        @store = store
      end

      # Resolve a name to a fully qualified namespace or constant.
      #
      # `Constants#resolve` finds fully qualified (absolute)
      # namespaces based on relative names and the open gates
      # (namespaces) provided.  Names must be runtime-visible (erased)
      # non-literal types, non-duck, non-signature types - e.g.,
      # TrueClass, NilClass, Integer and Hash instead of true, nil,
      # 96, or Hash{String => Symbol}
      #
      # Note: You may want to be using #qualify.  Notably, #resolve:
      # - does not handle anything with type parameters
      # - will not gracefully handle nil, self and Boolean
      # - will return a constant name instead of following its assignment
      #
      # @param name [String] Namespace which may relative and not be rooted.
      # @param gates [Array<Array<String>, String>] Namespaces to search while resolving the name
      #
      # @sg-ignore flow sensitive typing needs to eliminate literal from union with return if foo == :bar
      # @return [String, nil] fully qualified namespace (i.e., is
      #   absolute, but will not start with ::)
      def resolve(name, *gates)
        # @sg-ignore Need to add nil check here
        return store.get_path_pins(name[2..]).first&.path if name.start_with?('::')

        flat = gates.flatten
        flat.push '' if flat.empty?
        if cached_resolve.include? [name, flat]
          cached_result = cached_resolve[[name, flat]]
          # don't recurse
          return nil if cached_result == :in_process
          return cached_result
        end
        resolve_and_cache(name, flat)
      end

      # Get a fully qualified namespace from a reference pin.
      #
      # @param pin [Pin::Reference]
      # @return [String, nil]
      def dereference pin
        qualify_type(pin.type, *pin.reference_gates)&.tag
      end

      # Collect a list of all constants defined in the specified gates.
      #
      # @param gates [Array<Array<String>, String>]
      # @return [Array<Solargraph::Pin::Namespace, Solargraph::Pin::Constant>]
      def collect(*gates)
        flat = gates.flatten
        cached_collect[flat] || collect_and_cache(flat)
      end

      # Determine a fully qualified namespace for a given tag
      # referenced from the specified open gates. This method will
      # search in each gate until it finds a match for the name.
      #
      # @param tag [String, nil] The type to match
      # @param gates [Array<String>]
      # @return [String, nil] fully qualified tag
      def qualify tag, *gates
        type = ComplexType.try_parse(tag)
        qualify_type(type, *gates)&.tag
      end

      # @param type [ComplexType, nil] The type to match
      # @param gates [Array<String>]
      #
      # @return [ComplexType, nil] A new rooted ComplexType
      def qualify_type type, *gates
        return nil if type.nil?
        return type if type.selfy? || type.literal? || type.tag == 'nil' || type.interface? ||
                       type.tag == 'Boolean'

        gates.push '' unless gates.include?('')
        fqns = resolve(type.rooted_namespace, *gates)
        return unless fqns
        pin = store.get_path_pins(fqns).first
        if pin.is_a?(Pin::Constant)
          # @sg-ignore Need to add nil check here
          const = Solargraph::Parser::NodeMethods.unpack_name(pin.assignment)
          return unless const
          fqns = resolve(const, *pin.gates)
        end
        type.recreate(new_name: fqns, make_rooted: true)
      end

      # @return [void]
      def clear
        [cached_collect, cached_resolve].each(&:clear)
      end

      private

      # @return [Store]
      attr_reader :store

      # @param name [String]
      # @param gates [Array<String>]
      # @sg-ignore flow sensitive typing should be able to handle redefinition
      # @return [String, nil]
      def resolve_and_cache name, gates
        cached_resolve[[name, gates]] = :in_process
        cached_resolve[[name, gates]] = resolve_uncached(name, gates)
      end

      # @param name [String]
      # @param gates [Array<String>]
      # @return [String, nil]
      def resolve_uncached name, gates
        resolved = nil
        base = gates
        parts = name.split('::')
        first = nil
        parts.each.with_index do |nam, idx|
          resolved, remainder = complex_resolve(nam, base, idx != parts.length - 1)
          first ||= remainder
          if resolved
            base = [resolved]
          else
            # @sg-ignore flow sensitive typing needs better handling of ||= on lvars
            return resolve(name, first) unless first.empty?
          end
        end
        resolved
      end

      # @todo I'm not sure of a better way to express the return value in YARD.
      #   It's a tuple where the first element is a nullable string. Something
      #   like `Array(String|nil, Array<String>)` would be more accurate.
      #
      # @param name [String]
      # @param gates [Array<String>]
      # @param internal [Boolean] True if the name is not the last in the namespace
      # @return [Array(String, Array<String>), Array(nil, Array<String>), String]
      def complex_resolve name, gates, internal
        resolved = nil
        gates.each.with_index do |gate, idx|
          resolved = simple_resolve(name, gate, internal)
          return [resolved, gates[(idx + 1)..]] if resolved
          store.get_ancestor_references(gate).each do |ref|
            return ref.name.sub(/^::/, '') if ref.name.end_with?("::#{name}") && ref.name.start_with?('::')

            mixin = resolve(ref.name, ref.reference_gates)
            next unless mixin

            resolved = simple_resolve(name, mixin, internal)
            return [resolved, gates[(idx + 1)..]] if resolved
          end
        end
        [nil, []]
      end

      # @param name [String]
      # @param gate [String]
      # @param internal [Boolean] True if the name is not the last in the namespace
      # @return [String, nil]
      def simple_resolve name, gate, internal
        here = "#{gate}::#{name}".sub(/^::/, '').sub(/::$/, '')
        pin = store.get_path_pins(here).first
        if pin.is_a?(Pin::Constant) && internal
          # @sg-ignore Need to add nil check here
          const = Solargraph::Parser::NodeMethods.unpack_name(pin.assignment)
          return unless const
          resolve(const, pin.gates)
        else
          pin&.path
        end
      end

      # @param gates [Array<String>]
      # @return [Array<Solargraph::Pin::Namespace, Solargraph::Pin::Constant>]
      def collect_and_cache gates
        skip = Set.new
        cached_collect[gates] = gates.flat_map do |gate|
          inner_get_constants(gate, %i[public private], skip)
        end
      end

      # @return [Hash{Array(String, Array<String>) => String, :in_process, nil}]
      def cached_resolve
        @cached_resolve ||= {}
      end

      # @return [Hash{Array<String> => Array<Solargraph::Pin::Namespace, Solargraph::Pin::Constant>}]
      def cached_collect
        @cached_collect ||= {}
      end

      # Determine fully qualified namespace for a given namespace used
      # inside the definition of another tag ("context"). This method
      # will start the search in the specified context until it finds a
      # match for the namespace.
      #
      # @param namespace [String] The namespace to
      #   match
      # @param context_namespace [String] The context namespace in which the
      #   tag was referenced; start from here to resolve the name
      # @return [String, nil] fully qualified namespace
      def qualify_namespace namespace, context_namespace = ''
        if namespace.start_with?('::')
          # @sg-ignore Need to add nil check here
          inner_qualify(namespace[2..], '', Set.new)
        else
          inner_qualify(namespace, context_namespace, Set.new)
        end
      end

      # @param name [String] Namespace to fully qualify
      # @param root [String] The context to search
      # @param skip [Set<String>] Contexts already searched
      # @return [String, nil] Fully qualified ("rooted") namespace
      def inner_qualify name, root, skip
        return name if name == ComplexType::GENERIC_TAG_NAME
        return nil if name.nil?
        return nil if skip.include?(root)
        skip.add root
        possibles = []
        if name == ''
          return '' if root == ''

          inner_qualify(root, '', skip)
        else
          return name if root == '' && store.namespace_exists?(name)
          roots = root.to_s.split('::')
          while roots.length.positive?
            fqns = "#{roots.join('::')}::#{name}"
            return fqns if store.namespace_exists?(fqns)
            incs = store.get_includes(roots.join('::'))
            incs.each do |inc|
              foundinc = inner_qualify(name, inc.type.to_s, skip)
              possibles.push foundinc unless foundinc.nil?
            end
            roots.pop
          end
          if possibles.empty?
            incs = store.get_includes('')
            incs.each do |inc|
              foundinc = inner_qualify(name, inc.type.to_s, skip)
              possibles.push foundinc unless foundinc.nil?
            end
          end
          return name if store.namespace_exists?(name)
          possibles.last
        end
      end

      # @param fqns [String, nil]
      # @param visibility [Array<Symbol>]
      # @param skip [Set<String>]
      # @return [Array<Solargraph::Pin::Namespace, Solargraph::Pin::Constant>]
      def inner_get_constants fqns, visibility, skip
        return [] if fqns.nil? || skip.include?(fqns)
        skip.add fqns
        result = []

        store.get_prepends(fqns).each do |pre|
          # @sg-ignore Need to add nil check here
          pre_fqns = resolve(pre.name, pre.closure.gates - skip.to_a)
          result.concat inner_get_constants(pre_fqns, [:public], skip)
        end
        result.concat(store.get_constants(fqns, visibility).sort { |a, b| a.name <=> b.name })
        store.get_includes(fqns).each do |pin|
          # @sg-ignore Need to add nil check here
          inc_fqns = resolve(pin.name, pin.closure.gates - skip.to_a)
          result.concat inner_get_constants(inc_fqns, [:public], skip)
        end
        sc_ref = store.get_superclass(fqns)
        if sc_ref
          fqsc = dereference(sc_ref)
          # @sg-ignore Need to add nil check here
          result.concat inner_get_constants(fqsc, [:public], skip) unless %w[Object BasicObject].include?(fqsc)
        end
        result
      end
    end
  end
end
