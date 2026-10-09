# frozen_string_literal: true

module Solargraph
  module Convention
    # Maps the accessors ActiveSupport's +mattr_*+, +cattr_*+ and
    # +config_accessor+ macros define at run time.
    module ActiveSupportAccessors
      module NodeProcessors
        class AccessorNode < Parser::NodeProcessor::Base
          MACROS = %i[
            mattr_reader mattr_writer mattr_accessor
            cattr_reader cattr_writer cattr_accessor
            config_accessor
          ].freeze

          # Attribute names ActiveSupport accepts; it raises NameError on others.
          ATTRIBUTE_NAME = /\A[_A-Za-z]\w*\z/

          # @return [Boolean] continue processing the next processor of the same node.
          def process
            return true unless node.children[0].nil? && MACROS.include?(node.children[1])

            # Both macros refuse singleton classes.
            process_attributes unless region.scope == :class
            process_children
            false
          end

          private

          # Both macros define their accessors with a string +module_eval+,
          # so the accessors are public regardless of the enclosing visibility.
          #
          # @return [void]
          def process_attributes
            macro = node.children[1].to_s
            reader = !macro.end_with?('_writer')
            writer = !macro.end_with?('_reader')
            instance_accessor = boolean_option 'instance_accessor'
            instance_reader = reader && instance_accessor && boolean_option('instance_reader')
            instance_writer = writer && instance_accessor && boolean_option('instance_writer')
            node.children.drop(2).each do |a|
              next unless %i[sym str].include?(a.type)
              name = a.children[0].to_s
              next unless ATTRIBUTE_NAME.match?(name)
              if reader
                pins.push build_pin(name, scope: :class)
                pins.push build_pin(name, scope: :instance) if instance_reader
              end
              next unless writer
              pins.push build_pin("#{name}=", scope: :class, writer: true)
              pins.push build_pin("#{name}=", scope: :instance, writer: true) if instance_writer
            end
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
          # @return [Boolean] false only for a literal +false+ option
          def boolean_option name
            value = options[name]
            # rubocop:disable Lint/BooleanSymbol -- an AST node type
            value.nil? || value.type != :false
            # rubocop:enable Lint/BooleanSymbol
          end

          # @param name [String]
          # @param scope [Symbol] :class or :instance
          # @param writer [Boolean]
          # @return [Pin::Method]
          def build_pin name, scope:, writer: false
            pin = Pin::Method.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name,
              comments: comments_for(node),
              scope: scope,
              visibility: :public,
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
