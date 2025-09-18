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
      # @param name [String]
      # @param gates [Array<Array<String>, String>]
      # @return [String, nil]
      def resolve(name, *gates)
        return store.get_path_pins(name[2..]).first&.path if name.start_with?('::')

        flat = gates.flatten
        flat.push '' if flat.empty?
        cached_resolve[[name, flat]] || resolve_and_cache(name, flat)
      end

      # Get a fully qualified namespace from a reference pin.
      #
      # @param pin [Pin::Reference]
      # @return [String, nil]
      def dereference pin
        resolve(pin.name, pin.reference_gates)
      end

      # Collect a list of all constants defined in the specified gates.
      #
      # @param gates [Array<Array<String>, String>]
      # @return [Array<Pin::Base>]
      def collect(*gates)
        flat = gates.flatten
        cached_collect[flat] || collect_and_cache(flat)
      end

      # Determine a fully qualified namespace for a given name referenced
      # from the specified open gates. This method will search in each gate
      # until it finds a match for the name.
      #
      # @param name [String, nil] The namespace to match
      # @param gates [Array<String>]
      # @return [String, nil] fully qualified tag
      def qualify name, *gates
        return name if ['Boolean', 'self', nil].include?(name)

        gates.push '' unless gates.include?('')
        resolve(name, gates)
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
      # @return [String, nil]
      def resolve_and_cache name, gates
        cached_resolve[[name, gates]] = resolve_uncached(name, gates)
      end

      # @param name [String]
      # @param gates [Array<String>]
      # @return [String, nil]
      def resolve_uncached name, gates
        resolved = nil
        base = gates
        name.split('::').each do |nam|
          resolved = complex_resolve(nam, base)
          break unless resolved
          base = [resolved]
        end
        resolved
      end

      def complex_resolve name, gates
        resolved = nil
        gates.each do |gate|
          resolved = simple_resolve(name, gate)
          return resolved if resolved
          store.get_ancestor_references(gate).each do |ref|
            mixin = resolve(ref.name, ref.reference_gates - [gate])
            resolved = simple_resolve(name, mixin)
            return resolved if resolved
          end
        end
        nil
      end

      # @param name [String]
      # @param gate [String]
      # @return [String, nil]
      def simple_resolve name, gate
        here = "#{gate}::#{name}".sub(/^::/, '').sub(/::$/, '')
        here if store.constant_names.include?(here)
      end

      # @param gates [Array<String>]
      # @return [Array<Pin::Base>]
      def collect_and_cache gates
        skip = Set.new
        cached_collect[gates] = gates.flat_map do |gate|
          inner_get_constants(gate, %i[public private], skip)
        end
      end

      # @return [Hash{Array(Name, Array<String>) => String, nil}]
      def cached_resolve
        @cached_resolve ||= {}
      end

      # @return [Hash{Array<String> => Array<Pin::Base>}]
      def cached_collect
        @cached_collect ||= {}
      end

      # Determine fully qualified namespace for a given namespace used
      # inside the definition of another tag ("context"). This method
      # will start the search in the specified context until it finds a
      # match for the namespace.
      #
      # @param namespace [String, nil] The namespace to
      #   match
      # @param context_namespace [String] The context namespace in which the
      #   tag was referenced; start from here to resolve the name
      # @return [String, nil] fully qualified namespace
      def qualify_namespace namespace, context_namespace = ''
        if namespace.start_with?('::')
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
              foundinc = inner_qualify(name, inc.parametrized_tag.to_s, skip)
              possibles.push foundinc unless foundinc.nil?
            end
            roots.pop
          end
          if possibles.empty?
            incs = store.get_includes('')
            incs.each do |inc|
              foundinc = inner_qualify(name, inc.parametrized_tag.to_s, skip)
              possibles.push foundinc unless foundinc.nil?
            end
          end
          return name if store.namespace_exists?(name)
          possibles.last
        end
      end

      # @param fqns [String]
      # @param visibility [Array<Symbol>]
      # @param skip [Set<String>]
      # @return [Array<Pin::Base>]
      def inner_get_constants fqns, visibility, skip
        return [] if fqns.nil? || skip.include?(fqns)
        skip.add fqns
        result = []

        store.get_prepends(fqns).each do |pre|
          pre_fqns = resolve(pre.name, pre.closure.gates - skip.to_a)
          result.concat inner_get_constants(pre_fqns, [:public], skip)
        end
        result.concat(store.get_constants(fqns, visibility).sort { |a, b| a.name <=> b.name })
        store.get_includes(fqns).each do |pin|
          inc_fqns = resolve(pin.name, pin.closure.gates - skip.to_a)
          result.concat inner_get_constants(inc_fqns, [:public], skip)
        end
        sc_ref = store.get_superclass(fqns)
        if sc_ref
          fqsc = dereference(sc_ref)
          result.concat inner_get_constants(fqsc, [:public], skip) unless %w[Object BasicObject].include?(fqsc)
        end
        result
      end
    end
  end
end
