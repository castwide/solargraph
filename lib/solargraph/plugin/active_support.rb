# frozen_string_literal: true

module Solargraph
  module Plugin
    class ActiveSupport < Base
      def addon
        return EMPTY_ADDON unless gem_names.include?('activesupport')

        Addon.new(pins: classmethod_pins + attribute_pins)
      end

      private

      def classmethod_pins
        pins = pins_by_class(Pin::Reference::Include).map do |inc|
          Pin::Reference::Extend.new(name: "#{inc.name}::ClassMethods", closure: inc.closure)
        end
      end

      def attribute_pins
        source_maps.flat_map { |map| map.calls(:class_attribute, :mattr_accessor, :cattr_accessor) }
                   .flat_map { |call| generate_call_pins(call) }
                   .compact
      end

      # @param call [SourceMap::Call]
      def generate_call_pins call
        options = option_hash(call.chain.links.last.arguments.last)
        method_names = call.chain.links.last.arguments.select(&:literal?).map { |arg| arg.links.last.value }
        case call.chain.links.last.word
        when 'class_attribute'
          class_suffixes = ["", "=", "?"]
          instance_suffixes = []
          instance_suffixes.push "" if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push "=" if options[:instance_accessor] && options[:instance_writer]
          instance_suffixes.push "?" if options[:instance_predicate]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call.closure) }
        when 'mattr_accessor', 'cattr_accessor'
          class_suffixes = ["", "="]
          instance_suffixes = []
          instance_suffixes.push "" if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push "=" if options[:instance_accessor] && options[:instance_writer]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call.closure) }
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
        kwargs = Parser::ParserGem::NodeMethods.simple_convert(args.node).inspect
        return defaults unless kwargs.is_a?(Hash)
        defaults.merge(kwargs)
      end

      def method_pins name, class_suffixes, instance_suffixes, closure
        class_suffixes.map do |sfx|
          Pin::Method.new(name: "#{name}#{sfx}", closure: closure, scope: :class)
        end +
        instance_suffixes.map do |sfx|
          Pin::Method.new(name: "#{name}#{sfx}", closure: closure, scope: :instance)
        end
      end
    end
  end
end
