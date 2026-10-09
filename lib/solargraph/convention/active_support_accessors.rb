# frozen_string_literal: true

module Solargraph
  module Convention
    # Maps the accessors ActiveSupport's +class_attribute+, +mattr_*+,
    # +cattr_*+ and +config_accessor+ macros define at run time.
    module ActiveSupportAccessors
      module NodeProcessors
        class AccessorNode < Parser::NodeProcessor::Base
          MODULE_MACROS = %i[
            mattr_reader mattr_writer mattr_accessor
            cattr_reader cattr_writer cattr_accessor
            config_accessor
          ].freeze

          # Attribute names ActiveSupport accepts; it raises NameError on others.
          ATTRIBUTE_NAME = /\A[_A-Za-z]\w*\z/

          # @return [Boolean] continue processing the next processor of the same node.
          def process
            return true unless node.children[0].nil?

            if node.children[1] == :class_attribute
              process_class_attribute
            elsif MODULE_MACROS.include?(node.children[1])
              # Module attribute macros refuse singleton classes.
              process_module_attribute unless region.scope == :class
            else
              return true
            end
            process_children
            false
          end

          private

          # +class_attribute :name+ generates a singleton reader, writer and
          # predicate plus, unless disabled by options, an instance reader,
          # writer and predicate.
          #
          # @return [void]
          def process_class_attribute
            instance_accessor = boolean_option 'instance_accessor', true
            instance_reader = boolean_option 'instance_reader', instance_accessor
            instance_writer = boolean_option 'instance_writer', instance_accessor
            instance_predicate = boolean_option 'instance_predicate', true
            attribute_names.each do |name|
              next if name.empty?
              pins.push build_pin(name, scope: :class)
              pins.push build_pin("#{name}=", scope: :class, writer: true)
              pins.push build_pin("#{name}?", scope: :class) if instance_predicate
              if instance_reader
                pins.push build_pin(name, scope: :instance)
                pins.push build_pin("#{name}?", scope: :instance) if instance_predicate
              end
              pins.push build_pin("#{name}=", scope: :instance, writer: true) if instance_writer
            end
          end

          # Module attribute macros define their accessors with a string
          # +module_eval+, so the accessors are public regardless of the
          # enclosing visibility.
          #
          # @return [void]
          def process_module_attribute
            macro = node.children[1].to_s
            reader = !macro.end_with?('_writer')
            writer = !macro.end_with?('_reader')
            instance_accessor = boolean_option 'instance_accessor', true
            instance_reader = reader && instance_accessor && boolean_option('instance_reader', true)
            instance_writer = writer && instance_accessor && boolean_option('instance_writer', true)
            attribute_names.each do |name|
              next unless ATTRIBUTE_NAME.match?(name)
              if reader
                pins.push build_pin(name, scope: :class, visibility: :public)
                pins.push build_pin(name, scope: :instance, visibility: :public) if instance_reader
              end
              next unless writer
              pins.push build_pin("#{name}=", scope: :class, writer: true, visibility: :public)
              pins.push build_pin("#{name}=", scope: :instance, writer: true, visibility: :public) if instance_writer
            end
          end

          # @return [Array<String>] the literal symbol and string arguments
          def attribute_names
            node.children.drop(2).select { |a| %i[sym str].include?(a.type) }.map { |a| a.children[0].to_s }
          end

          # The literal keyword arguments passed to the macro. Values which
          # cannot be evaluated statically are ignored.
          #
          # @return [Hash{String => ::Parser::AST::Node}]
          def options
            hash = node.children.drop(2).last
            return {} if hash.nil? || hash.type != :hash
            # @type [Hash{String => ::Parser::AST::Node}]
            result = {}
            hash.children.each do |pair|
              key, value = pair.children
              next if pair.type != :pair || key.nil? || value.nil? || !%i[sym str].include?(key.type)
              result[key.children[0].to_s] = value
            end
            result
          end

          # @param name [String]
          # @param default [Boolean]
          # @return [Boolean] the literal +true+ or +false+ option, else the default
          def boolean_option name, default
            value = options[name]
            return default if value.nil?
            # rubocop:disable Lint/BooleanSymbol -- AST node types
            return true if value.type == :true
            return false if value.type == :false
            # rubocop:enable Lint/BooleanSymbol
            default
          end

          # @param name [String]
          # @param scope [Symbol] :class or :instance
          # @param writer [Boolean]
          # @param visibility [Symbol]
          # @return [Pin::Method]
          def build_pin name, scope:, writer: false, visibility: region.visibility
            pin = Pin::Method.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name,
              comments: comments_for(node),
              scope: scope,
              visibility: visibility,
              attribute: true,
              source: :active_support_accessors
            )
            if writer
              pin.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pin,
                                                     source: :active_support_accessors)
            end
            pin
          end
        end
      end
    end
  end
end
