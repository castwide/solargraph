# frozen_string_literal: true

module Solargraph
  class ApiMap
    # Methods for handling constants.
    #
    class Constants
      # @param store [Store]
      def initialize(store)
        @store = store
      end

      # Resolve a name to a fully qualified namespace or constant.
      #
      # @param name [String]
      # @param gates [Array<Array<String>, String>]
      # @return [String, nil]
      def resolve(name, *gates)
        if name.start_with?('::')
          return store.get_path_pins(name[2..]).any? ? name[2..] : nil
        end

        flat = gates.flatten
        flat.push '' if flat.empty?
        cached_resolve[[name, flat]] || resolve_and_cache(name, flat)
      end

      # Get a fully qualified namespace from a reference pin.
      #
      # @param pin [Pin::Reference]
      # @return [String, nil]
      def dereference(pin)
        resolve(pin.name, pin.allowed_gates)
      end

      # Collect a list of all constants defined in the specified gates.
      #
      # @param gates [Array<Array<String>, String>]
      # @return [Array<Pin::Base>]
      def collect(*gates)
        flat = gates.flatten
        cached_collect[flat] || collect_and_cache(flat)
      end

      # Determine fully qualified tag for a given tag used inside the
      # definition of another tag ("context"). This method will start
      # the search in the specified context until it finds a match for
      # the tag.
      #
      # Does not recurse into qualifying the type parameters, but
      # returns any which were passed in unchanged.
      #
      # @param tag [String, nil] The namespace to
      #   match, complete with generic parameters set to appropriate
      #   values if available
      # @param context_tag [String] The fully qualified context in which
      #   the tag was referenced; start from here to resolve the name.
      #   Should not be prefixed with '::'.
      # @return [String, nil] fully qualified tag
      def qualify tag, context_tag = ''
        return tag if ['Boolean', 'self', nil].include?(tag)

        context_type = ComplexType.try_parse(context_tag).force_rooted
        return unless context_type

        type = ComplexType.try_parse(tag)
        return unless type
        return tag if type.literal?

        context_type = ComplexType.try_parse(context_tag)
        return unless context_type

        fqns = qualify_namespace(type.rooted_namespace, context_type.rooted_namespace)
        return unless fqns

        fqns + type.substring
      end

      private

      # @return [Store]
      attr_reader :store

      # @param name [String]
      # @param gates [Array<String>]
      # @return [String]
      def resolve_and_cache name, gates
        cached_resolve[[name, gates]] = resolve_uncached(name, gates)
      end

      def resolve_uncached name, gates
        gates.each do |gate|
          resolved = collect(name, gate).map(&:path).find { |ns| ns if "::#{ns}".end_with?("::#{name}") }
          return resolved if resolved
        end
        nil
      end

      # @param gates [Array<String>]
      # @return [Array<Pin::Base>]
      def collect_and_cache gates
        skip = Set.new
        cached_collect[gates] = gates.flat_map do |gate|
          inner_get_constants(gate, [:public, :private], skip)
        end
      end

      def cached_resolve
        @cached_resolve ||= {}
      end

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
      def qualify_namespace(namespace, context_namespace = '')
        if namespace.start_with?('::')
          inner_qualify(namespace[2..-1], '', Set.new)
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
          if root == ''
            return ''
          else
            return inner_qualify(root, '', skip)
          end
        else
          return name if root == '' && store.namespace_exists?(name)
          roots = root.to_s.split('::')
          while roots.length > 0
            fqns = roots.join('::') + '::' + name
            return fqns if store.namespace_exists?(fqns)
            incs = store.get_includes(roots.join('::'))
            incs.each do |inc|
              foundinc = inner_qualify(name, inc.parametrized_tag, skip)
              possibles.push foundinc unless foundinc.nil?
            end
            roots.pop
          end
          if possibles.empty?
            incs = store.get_includes('')
            incs.each do |inc|
              foundinc = inner_qualify(name, inc.parametrized_tag, skip)
              possibles.push foundinc unless foundinc.nil?
            end
          end
          return name if store.namespace_exists?(name)
          return possibles.last
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
        fqsc = qualify_superclass(fqns)
        unless %w[Object BasicObject].include?(fqsc)
          result.concat inner_get_constants(fqsc, [:public], skip)
        end
        result
      end

      # @param fq_sub_tag [String]
      # @return [String, nil]
      def qualify_superclass fq_sub_tag
        fq_sub_type = ComplexType.try_parse(fq_sub_tag)
        fq_sub_ns = fq_sub_type.name
        sup_tag = store.get_superclass(fq_sub_tag)
        sup_type = ComplexType.try_parse(sup_tag)
        sup_ns = sup_type.name
        return nil if sup_tag.nil?
        parts = fq_sub_ns.split('::')
        last = parts.pop
        parts.pop if last == sup_ns
        qualify(sup_tag, parts.join('::'))
      end
    end
  end
end
