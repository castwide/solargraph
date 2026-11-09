# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        module StringEvalDefinitions
          # Maps the methods that templates define, at each call
          # with literal arguments to a method that carries them:
          #
          #   def self.flag(name)
          #     class_eval "def #{name}?; true; end"
          #   end
          #   flag :admin                           # => #admin? on the caller
          #   routes.define_mounted_helper(:blog)   # => #blog on the template's
          #                                         #    target, if routes is typed
          #
          # The callee is resolved like any other call, so a receiver of unknown
          # type maps nothing.
          #
          class CallSites
            # @param api_map [ApiMap]
            def initialize api_map
              @api_map = api_map
            end

            # @return [Array<Pin::Base>]
            def pins
              template_pins = api_map.call_site_template_pins.select { |_name, pins| pins.any? { |pin| templates?(pin) } }
              names = template_pins.keys.to_set
              return [] if names.empty?
              api_map.source_maps.flat_map do |source_map|
                source_map.method_call_nodes.flat_map do |node|
                  next [] unless node.type == :send && names.include?(node.children[1].to_s)
                  pins_for_call(source_map, node)
                end
              end
            end

            private

            # @return [ApiMap]
            attr_reader :api_map

            # @param pin [Pin::Method]
            def templates? pin
              pin.call_site_templates.any? { |template| template.is_a?(Template) }
            end

            # @param source_map [SourceMap]
            # @param node [::Parser::AST::Node]
            # @return [Array<Pin::Base>]
            def pins_for_call source_map, node
              range = Range.from_node(node)
              return [] if range.nil?
              location = Location.new(source_map.filename, range)
              closure = source_map.locate_closure_pin(location.range.start.line, location.range.start.character)
              locals = source_map.locals_at(location)
              callees = Parser::ParserGem::NodeChainer.chain(node).define(api_map, closure, locals)
              callee = callees.find { |pin| pin.is_a?(Pin::Method) && templates?(pin) }
              return [] unless callee.is_a?(Pin::Method)
              params = literal_arguments(callee, node)
              receiver = receiver_namespace(node.children[0], closure, locals)
              callee.call_site_templates.flat_map do |template|
                next [] unless template.is_a?(Template)
                target = target_namespace(template, receiver)
                next [] if target.nil?
                template.expand(params).flat_map do |code|
                  StringEvalDefinitions.map(code, location.filename, location.range.start.line, target, template.scope)
                end
              end
            end

            # The literal values passed for each of the callee's parameters.
            # Parameters that receive anything else are left out.
            #
            # @param callee [Pin::Method]
            # @param node [::Parser::AST::Node]
            # @return [Hash{String => Array<String>}]
            def literal_arguments callee, node
              # @type [Array<::Parser::AST::Node>]
              positional = node.children.drop(2).grep(::Parser::AST::Node)
              last = positional.last
              keywords = last&.type == :hash ? positional.pop : nil
              # @type [Hash{String => Array<String>}]
              result = {}
              callee.parameters.each do |param|
                case param.decl
                when :arg, :optarg
                  value = positional.shift
                  result[param.name] = literal_values(value) if value
                when :restarg
                  result[param.name] = positional.flat_map { |value| literal_values(value) }
                  positional = []
                when :kwarg, :kwoptarg
                  result[param.name] = literal_values(keyword_value(keywords, param.name))
                end
              end
              result
            end

            # @param node [Object]
            # @return [Array<String>]
            def literal_values node
              return [] unless node.is_a?(AST::Node)
              return [node.children[0].to_s] if %i[str sym].include?(node.type)
              return node.children.flat_map { |child| literal_values(child) } if node.type == :array
              []
            end

            # @param hash [::Parser::AST::Node, nil]
            # @param name [String]
            # @return [Object]
            def keyword_value hash, name
              return if hash.nil?
              hash.children.each do |pair|
                next unless pair.is_a?(AST::Node) && pair.type == :pair
                key, value = pair.children
                return value if key.is_a?(AST::Node) && key.type == :sym && key.children[0].to_s == name
              end
              nil
            end

            # The namespace a call's receiver refers to, if it is a class or module.
            #
            # @param receiver [::Parser::AST::Node, nil]
            # @param closure [Pin::Closure]
            # @param locals [Array<Pin::LocalVariable>]
            # @return [String, nil]
            def receiver_namespace receiver, closure, locals
              type = if receiver.nil? || receiver.type == :self
                       closure.binder
                     else
                       Parser::ParserGem::NodeChainer.chain(receiver).infer_uncached(api_map, closure, locals)
                     end
              return unless type.defined? && %w[Class Module].include?(type.name)
              type.namespace
            end

            # @param template [Template]
            # @param receiver [String, nil]
            # @return [Pin::Namespace, nil]
            def target_namespace template, receiver
              path = if template.target.nil?
                       receiver
                     else
                       api_map.qualify(template.target, *template.gates)
                     end
              return if path.nil? || path.empty?
              path = path.delete_prefix('::')
              found = api_map.get_path_pins(path).find { |pin| pin.is_a?(Pin::Namespace) }
              found.is_a?(Pin::Namespace) ? found : Pin::Namespace.new(name: path, closure: Pin::ROOT_PIN, source: :parser)
            end
          end
        end
      end
    end
  end
end
