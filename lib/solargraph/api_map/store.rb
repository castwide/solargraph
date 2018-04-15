require 'set'

module Solargraph
  class ApiMap
    class Store
      def initialize seeds
        seeds.each do |seed|
          pins.concat seed.pins
          symbols.concat seed.symbols
        end
        index
      end

      def pins
        @pins ||= []
      end

      def remove source
        pins.delete_if { |pin| pin.filename == source.filename }
        symbols.delete_if { |pin| pin.filename == source.filename }
        index
      end

      def update source
        pins.delete_if { |pin| pin.filename == source.filename }
        symbols.delete_if { |pin| pin.filename == source.filename }
        pins.concat source.pins
        symbols.concat source.symbols
        index
      end

      def get_constants fqns, visibility = [:public]
        namespace_pins(fqns).select { |pin|
          (pin.kind == Pin::NAMESPACE or pin.kind == Pin::CONSTANT) and visibility.include?(pin.visibility)
        }
      end

      def get_methods fqns, scope: :instance, visibility: [:public]
        namespace_pins(fqns).select{ |pin|
          pin.kind == Pin::METHOD and (pin.scope == scope or fqns == '') and visibility.include?(pin.visibility)
        }
      end

      def get_attrs fqns
        namespace_pins(fqns).select{ |pin| pin.kind == Pin::ATTRIBUTE }
      end

      def get_superclass fqns
        fqns_pins(fqns).each do |pin|
          return pin.superclass_reference.name unless pin.superclass_reference.nil?
        end
        nil
      end

      def get_includes fqns
        result = []
        fqns_pins(fqns).each do |pin|
          result.concat pin.include_references.map(&:name)
        end
        result
      end

      def get_extends fqns
        result = []
        fqns_pins(fqns).each do |pin|
          result.concat pin.extend_references.map(&:name)
        end
        result
      end

      def get_path_pins path
        base = path.sub(/(#|\.|::)[a-z0-9_]*(\?|\!)?$/i, '')
        base = '' if base == path
        namespace_pins(base).select{ |pin| pin.path == path }
      end

      def get_instance_variables(fqns, scope = :instance)
        namespace_pins(fqns).select{|pin| pin.kind == Pin::INSTANCE_VARIABLE and pin.scope == scope}
      end

      def get_symbols
        symbols.uniq(&:name)
      end

      def namespace_exists?(fqns)
        fqns_pins(fqns).any?
      end

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
