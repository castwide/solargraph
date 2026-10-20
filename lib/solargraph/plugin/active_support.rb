# frozen_string_literal: true

module Solargraph
  module Plugin
    class ActiveSupport < Base
      ATTRIBUTE_NAME = /\A[_A-Za-z]\w*\z/
      EMPTY_ADDON = Addon.new.freeze

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
        source_maps.flat_map { |map| map.calls(:class_attribute, :mattr_accessor, :cattr_accessor, :mattr_reader, :cattr_reader, :mattr_writer, :cattr_writer, :config_accessor) }
                   .select { |call| call.closure.is_a?(Pin::Namespace) }
                   .flat_map { |call| generate_call_pins(call) }
                   .compact
      end

      # @param call [SourceMap::Call]
      def generate_call_pins call
        options = option_hash(call.chain.links.last.arguments.last)
        method_names = call.chain.links.last.arguments.select(&:literal?).map { |arg| arg.links.last.value }.compact
                           .select { |name| name =~ ATTRIBUTE_NAME }
        case call.chain.links.last.word
        when 'class_attribute'
          class_suffixes = ["", "="]
          class_suffixes.push "?" if options[:instance_predicate]
          instance_suffixes = []
          instance_suffixes.push "" if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push "=" if options[:instance_accessor] && options[:instance_writer]
          instance_suffixes.push "?" if options[:instance_accessor] && options[:instance_predicate]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_accessor', 'cattr_accessor', 'config_accessor'
          class_suffixes = ["", "="]
          instance_suffixes = []
          instance_suffixes.push "" if options[:instance_accessor] && options[:instance_reader]
          instance_suffixes.push "=" if options[:instance_accessor] && options[:instance_writer]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_reader', 'cattr_reader'
          class_suffixes = [""]
          instance_suffixes = []
          instance_suffixes.push "" if options[:instance_accessor] && options[:instance_reader]
          method_names.flat_map { |name| method_pins(name, class_suffixes, instance_suffixes, call) }
        when 'mattr_writer', 'cattr_writer'
          class_suffixes = ["="]
          instance_suffixes = []
          instance_suffixes.push "=" if options[:instance_accessor] && options[:instance_writer]
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
