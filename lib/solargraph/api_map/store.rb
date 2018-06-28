require 'set'

module Solargraph
  class ApiMap
    class Store
      # @param sources [Solargraph::Source]
      def initialize sources
        update *sources
        index
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      def remove *sources
        sources.each do |source|
          pins.delete_if { |pin| pin.filename == source.filename }
          symbols.delete_if { |pin| pin.filename == source.filename }
        end
        index
      end

      def update *sources
        sources.each do |source|
          pins.delete_if { |pin| pin.filename == source.filename }
          symbols.delete_if { |pin| pin.filename == source.filename }
          pins.concat source.pins
          symbols.concat source.symbols
        end
        index
      end

      # @return [Array<Solargraph::Pin::Base>]
      def get_constants fqns, visibility = [:public]
        namespace_pins(fqns).select { |pin|
          !pin.name.empty? and (pin.kind == Pin::NAMESPACE or pin.kind == Pin::CONSTANT) and visibility.include?(pin.visibility)
        }
      end

      def get_methods fqns, scope: :instance, visibility: [:public]
        namespace_pins(fqns).select{ |pin|
          pin.kind == Pin::METHOD and (pin.scope == scope or fqns == '') and visibility.include?(pin.visibility)
        }
      end

      # @return [Array<Solargraph::Pin::Base>]
      def get_attrs fqns, scope
        namespace_pins(fqns).select{ |pin| pin.kind == Pin::ATTRIBUTE and pin.scope == scope }
      end

      # @param fqns [String]
      # @return [String]
      def get_superclass fqns
        fqns_pins(fqns).each do |pin|
          return pin.superclass_reference.name unless pin.superclass_reference.nil?
        end
        nil
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_includes fqns
        result = []
        fqns_pins(fqns).each do |pin|
          result.concat pin.include_references.map(&:name)
        end
        result
      end

      # @param fqns [String]
      # @return [Array<String>]
      def get_extends fqns
        result = []
        fqns_pins(fqns).each do |pin|
          result.concat pin.extend_references.map(&:name)
        end
        result
      end

      # @param path [String]
      # @return [Array<Solargraph::Pin::Base>]
      def get_path_pins path
        base = path.sub(/(#|\.|::)[a-z0-9_]*(\?|\!)?$/i, '')
        base = '' if base == path
        namespace_pins(base).select{ |pin| pin.path == path }
      end

      # @param fqns [String]
      # @param scope [Symbol] :class or :instance
      # @return [Array<Solargraph::Pin::Base>]
      def get_instance_variables(fqns, scope = :instance)
        namespace_pins(fqns).select{|pin| pin.kind == Pin::INSTANCE_VARIABLE and pin.scope == scope}
      end

      # @param fqns [String]
      # @return [Array<Solargraph::Pin::Base>]
      def get_class_variables(fqns)
        namespace_pins(fqns).select{|pin| pin.kind == Pin::CLASS_VARIABLE}
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

      private

      def fqns_pins fqns
        # @todo We probably want to ignore '' namespace here
        return [] if fqns.nil? #or fqns.empty?
        if fqns.include?('::')
          parts = fqns.split('::')
          name = parts.pop
          base = parts.join('::')
        else
          base = ''
          name = fqns
        end
        namespace_pins(base).select{|pin| pin.name == name and pin.kind == Pin::NAMESPACE}
      end

      def symbols
        @symbols ||= []
      end

      def namespace_pins name
        namespace_map[name] || []
      end

      def namespace_map
        @namespace_map ||= {}
      end

      def index
        namespace_map.clear
        namespaces.clear
        namespace_map[''] = []
        pins.each do |pin|
          namespace_map[pin.namespace] ||= []
          namespace_map[pin.namespace].push pin
          namespaces.add pin.path if pin.kind == Pin::NAMESPACE and !pin.path.empty?
        end
      end
    end
  end
end
