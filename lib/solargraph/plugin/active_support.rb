# frozen_string_literal: true

module Solargraph
  module Plugin
    class ActiveSupport < Base
      ATTRIBUTE_NAME = /\A[_A-Za-z]\w*\z/

      def addon
        return EMPTY_ADDON unless gem_names.include?('activesupport')

        Addon.new(pins: classmethod_pins + attribute_pins)
      end

      private

      # @return [Array<Pin::Reference::Extend>]
      def classmethod_pins
        include_pins.flat_map do |inc|
          nested = nested_include_paths(inc).uniq.select { |path| namespace_paths.include?("#{path}::ClassMethods") }
          ["#{inc.name}::ClassMethods", *nested.map { |path| "::#{path}::ClassMethods" }].map do |name|
            Pin::Reference::Extend.new(name: name, closure: inc.closure)
          end
        end
      end

      # @return [Array<Pin::Reference::Include>]
      def include_pins
        @include_pins ||= (panel.pins + panel.external_pins).grep(Pin::Reference::Include)
      end

      # @return [Hash{String => Array<Pin::Reference::Include>}]
      def include_pins_by_namespace
        @include_pins_by_namespace ||= include_pins.group_by { |inc| inc.closure&.path.to_s }
      end

      # @return [Set<String>]
      def namespace_paths
        @namespace_paths ||= (panel.pins + panel.external_pins).grep(Pin::Namespace).to_set(&:path)
      end

      # Paths of the modules that an included module includes, at any
      # depth. A concern's dependencies extend the includer with their
      # ClassMethods too.
      #
      # @param inc [Pin::Reference::Include]
      # @param visited [Set<String>]
      # @return [Array<String>]
      def nested_include_paths inc, visited = Set.new
        path = resolve_include(inc)
        return [] if path.nil? || !visited.add?(path)

        include_pins_by_namespace.fetch(path, []).flat_map do |nested|
          nested_path = resolve_include(nested)
          nested_path.nil? ? [] : [nested_path, *nested_include_paths(nested, visited)]
        end
      end

      # Resolve an include's module name lexically from its namespace.
      #
      # @param inc [Pin::Reference::Include]
      # @return [String, nil]
      def resolve_include inc
        return inc.name.delete_prefix('::') if inc.name.start_with?('::')

        parts = inc.closure&.path.to_s.split('::')
        candidates = parts.length.downto(0).map { |len| [*parts.first(len), inc.name].join('::') }
        candidates.find { |candidate| namespace_paths.include?(candidate) }
      end

      def attribute_pins
        source_maps.flat_map { |map| map.calls(:class_attribute, :mattr_accessor, :cattr_accessor, :mattr_reader, :cattr_reader, :mattr_writer, :cattr_writer, :config_accessor) }
                   .select { |call| call.closure.is_a?(Pin::Namespace) }
                   .flat_map { |call| generate_call_pins(call) }
                   .compact
      end

      # @param call [SourceMap::Call]
      def generate_call_pins call
        options = option_hash(call.chain.links.last.arguments.last)
        method_names = call.chain.links.last.arguments.select(&:literal?).map { |arg| arg.links.last.value }.compact
                           .grep(ATTRIBUTE_NAME)
        case call.chain.links.last.word
        when 'class_attribute'
          class_suffixes = ['', '=']
          class_suffixes.push '?' if options[:instance_predicate]
          instance_suffixes = []
          instance_suffixes.push '' if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push '=' if options[:instance_accessor] && options[:instance_writer]
          instance_suffixes.push '?' if options[:instance_accessor] && options[:instance_predicate]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_accessor', 'cattr_accessor', 'config_accessor'
          class_suffixes = ['', '=']
          instance_suffixes = []
          instance_suffixes.push '' if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push '=' if options[:instance_accessor] && options[:instance_writer]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_reader', 'cattr_reader'
          class_suffixes = ['']
          instance_suffixes = []
          instance_suffixes.push '' if options[:instance_accessor] && options[:instance_reader]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_writer', 'cattr_writer'
          class_suffixes = ['=']
          instance_suffixes = []
          instance_suffixes.push '=' if options[:instance_accessor] && options[:instance_writer]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        else
          []
        end
      end

      def option_hash args
        defaults = {
          instance_reader: true,
          instance_writer: true,
          instance_accessor: true,
          instance_predicate: true
        }
        kwargs = Parser::ParserGem::NodeMethods.convert_hash(args.node)
                                               .select { |_, val| val.literal? }
                                               .transform_values { |val| val.links.last.value }
        return defaults unless kwargs.is_a?(Hash)
        defaults.merge(kwargs)
      end

      # @param call [SourceMap::Call]
      # @param name [String]
      # @param class_suffixes [Array<String>]
      # @param instance_suffixes [Array<String>]
      def method_pins name, class_suffixes, instance_suffixes, call
        comments = call.source_map.source.comments_for(call.chain.node)
        location = Solargraph::Location.new(call.closure.filename, Solargraph::Range.from_node(call.chain.node))
        class_suffixes.map do |sfx|
          Pin::Method.new(name: "#{name}#{sfx}", closure: call.closure, scope: :class, attribute: true, location: location, comments: comments).tap do |pin|
            next unless sfx == '='
            pin.parameters.push Pin::Parameter.new(name: 'value', closure: pin)
          end
        end +
          instance_suffixes.map do |sfx|
            Pin::Method.new(name: "#{name}#{sfx}", closure: call.closure, scope: :instance, attribute: true, location: location, comments: comments).tap do |pin|
              next unless sfx == '='
              pin.parameters.push Pin::Parameter.new(name: 'value', closure: pin)
            end
          end
      end
    end
  end
end
