require 'set'

module Solargraph
  class ApiMap
    class Store
      attr_reader :pins

      # @param sources [Array<Solargraph::Source>]
      # @param yard_pins [Array<Solargraph::Pin::Base>]
      def initialize pins
        # inner_update sources
        # pins.concat yard_pins
        @pins = pins
        index
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      # @param *sources [Array<Solargraph::Source>]
      # @return [void]
      def remove *sources
        sources.each do |source|
          pins.delete_if { |pin| !pin.yard_pin? and pin.filename == source.filename }
          symbols.delete_if { |pin| pin.filename == source.filename }
        end
        index
      end

      # @param *sources [Array<Solargraph::Source>]
      # @return [void]
      def update *sources
        inner_update sources
        index
      end

      # @param yard_pins [Array<Solargraph::Pin::Base>]
      # @return [void]
      def update_yard yard_pins
        pins.delete_if(&:yard_pin?)
        pins.concat yard_pins
        index
      end

      # @param fqns [String]
      # @param visibility [Array<Symbol>]
      # @return [Array<Solargraph::Pin::Base>]
      def get_constants fqns, visibility = [:public]
        namespace_children(fqns).select { |pin|
          !pin.name.empty? and (pin.kind == Pin::NAMESPACE or pin.kind == Pin::CONSTANT) and visibility.include?(pin.visibility)
        }
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @param visibility [Array<Symbol>]
      # @return [Array<Solargraph::Pin::Base>]
      def get_methods fqns, scope: :instance, visibility: [:public]
        namespace_children(fqns).select{ |pin|
          pin.kind == Pin::METHOD and (pin.scope == scope or fqns == '') and visibility.include?(pin.visibility)
        }
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @return [Array<Solargraph::Pin::Base>]
      def get_attrs fqns, scope
        namespace_children(fqns).select{ |pin| pin.kind == Pin::ATTRIBUTE and pin.scope == scope }
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
        # return [] if path.nil? # @todo Should be '' instead?
        path ||= ''
        base = path.sub(/(#|\.|::)[a-z0-9_]*(\?|\!)?$/i, '')
        base = '' if base == path
        namespace_children(base).select{ |pin| pin.path == path }
      end

      # @param fqns [String]
      # @param scope [Symbol] :class or :instance
      # @return [Array<Solargraph::Pin::Base>]
      def get_instance_variables(fqns, scope = :instance)
        namespace_children(fqns).select{|pin| pin.kind == Pin::INSTANCE_VARIABLE and pin.scope == scope}
      end

      # @param fqns [String]
      # @return [Array<Solargraph::Pin::Base>]
      def get_class_variables(fqns)
        namespace_children(fqns).select{|pin| pin.kind == Pin::CLASS_VARIABLE}
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
        @namespace_pins ||= pins.select{|p| p.kind == Pin::NAMESPACE}
      end

      # @return [Array<Solargraph::Pin::Base>]
      def method_pins
        @method_pins ||= pins.select{|p| p.kind == Pin::METHOD or p.kind == Pin::ATTRIBUTE}
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
        namespace_children(base).select{|pin| pin.name == name and pin.kind == Pin::NAMESPACE}
      end

      # @return [Array<Solargraph::Pin::Symbol>]
      def symbols
        @symbols ||= []
      end

      # @param name [String]
      # @return [Array<Solargraph::Pin::Namespace>]
      def namespace_children name
        namespace_map[name] || []
      end

      # @return [Hash]
      def namespace_map
        @namespace_map ||= {}
      end

      # @return [void]
      def index
        namespace_map.clear
        namespaces.clear
        symbols.clear
        namespace_map[''] = []
        pins.each do |pin|
          namespace_map[pin.namespace] ||= []
          namespace_map[pin.namespace].push pin
          namespaces.add pin.path if pin.kind == Pin::NAMESPACE and !pin.path.empty?
          symbols.push pin if pin.kind == Pin::SYMBOL
        end
        @namespace_pins = nil
        @method_pins = nil
      end

      # @param sources [Array<Solargraph::Source>]
      # @return [void]
      def inner_update sources
        sources.each do |source|
          pins.delete_if { |pin| !pin.yard_pin? and pin.filename == source.filename }
          symbols.delete_if { |pin| pin.filename == source.filename }
          pins.concat source.pins
          symbols.concat source.symbols
        end
      end
    end
  end
end
