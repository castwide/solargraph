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
        panel.pins_by_class(Pin::Reference::Include).map do |inc|
          Pin::Reference::Extend.new(name: "#{inc.name}::ClassMethods", closure: inc.closure)
        end
      end

      # @return [Array<Pin::Method>]
      def attribute_pins
        panel.source_maps.flat_map { |map| map.calls(:class_attribute, :mattr_accessor, :cattr_accessor, :mattr_reader, :cattr_reader, :mattr_writer, :cattr_writer, :config_accessor) }
             .select { |call| call.closure.is_a?(Pin::Namespace) }
             .flat_map { |call| generate_call_pins(call) }
             .compact
      end

      # @param call [SourceMap::Call]
      # @return [Array<Pin::Method>, nil]
      def generate_call_pins call
        link = call.chain.links.last
        return [] unless link.is_a?(Source::Chain::Call)

        options = option_hash(link.arguments.last)
        method_names = link.arguments.map { |arg| arg.links.last }.grep(Source::Chain::Literal).map(&:value).compact
                           .grep(ATTRIBUTE_NAME)
        case link.word
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
        end
      end

      # @param args [Source::Chain, nil]
      # @return [Hash{Symbol => Object}]
      def option_hash args
        defaults = {
          instance_reader: true,
          instance_writer: true,
          instance_accessor: true,
          instance_predicate: true
        }
        return defaults unless args

        kwargs = Parser::ParserGem::NodeMethods.convert_hash(args.node)
                                               .select { |_, val| val.literal? }
                                               # @sg-ignore Chain#literal? does not narrow links.last to Chain::Literal
                                               .transform_values { |val| val.links.last.value }
        return defaults unless kwargs.is_a?(Hash)
        defaults.merge(kwargs)
      end

      # @param call [SourceMap::Call]
      # @param name [String]
      # @param class_suffixes [Array<String>]
      # @param instance_suffixes [Array<String>]
      # @return [Array<Pin::Method>]
      def method_pins name, class_suffixes, instance_suffixes, call
        closure = call.closure
        node = call.chain.node
        range = node && Solargraph::Range.from_node(node)
        return [] unless closure && node && range

        comments = call.source_map.source.comments_for(node)
        location = Solargraph::Location.new(closure.filename, range)
        class_suffixes.map do |sfx|
          Pin::Method.new(name: "#{name}#{sfx}", closure: closure, scope: :class, attribute: true, location: location, comments: comments).tap do |pin|
            next unless sfx == '='
            pin.parameters.push Pin::Parameter.new(name: 'value', closure: pin)
          end
        end +
          instance_suffixes.map do |sfx|
            Pin::Method.new(name: "#{name}#{sfx}", closure: closure, scope: :instance, attribute: true, location: location, comments: comments).tap do |pin|
              next unless sfx == '='
              pin.parameters.push Pin::Parameter.new(name: 'value', closure: pin)
            end
          end
      end
    end
  end
end
