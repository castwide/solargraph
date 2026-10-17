# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SendNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @sg-ignore @override is adding, not overriding
          def process
            # s(:send, receiver, method_name, *args)
            node => [:send, ::Parser::AST::Node | nil => receiver, Symbol => method_name, *args]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            if receiver.nil?
              if %i[private public protected].include?(method_name)
                process_visibility
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :module_function
                process_module_function
              elsif %i[attr_reader attr_writer attr_accessor].include?(method_name)
                process_attribute
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :class_attribute
                process_class_attribute
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :include
                process_include
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :extend
                process_extend
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :prepend
                process_prepend
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :require
                process_require
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :autoload
                process_autoload
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :private_constant
                process_private_constant
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :alias_method && (args in [[:sym, *], [:sym, *], *])
                process_alias_method
              elsif %i[def_delegator def_delegators].include?(method_name) && extends_forwardable?
                process_def_delegators
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              elsif method_name == :private_class_method && (args in [::AST::Node, *])
                # Processing a private class can potentially handle children on its own
                return if process_private_class_method
              end
            elsif %i[include extend prepend].include?(method_name) && (receiver in [:const, *])
              process_qualified_mixin method_name
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            elsif method_name == :require && (receiver in [:const, nil, :Bundler])
              pins.push Pin::Reference::Require.new(
                Solargraph::Location.new(region.filename,
                                         Solargraph::Range.from_to(0, 0, 0, 0)), 'bundler/require', source: :parser
              )
            end
            process_children
          end

          private

          # True when the enclosing namespace extends Forwardable, which is
          # what makes def_delegator and def_delegators available there.
          # Matched by name only, so a same-named local module would fool this.
          #
          # @return [Boolean]
          def extends_forwardable?
            pins.any? do |pin|
              pin.is_a?(Pin::Reference::Extend) &&
                pin.closure == region.closure &&
                ['Forwardable', '::Forwardable'].include?(pin.name)
            end
          end

          # The word behind a symbol or string node, e.g. :@records or "size".
          #
          # @param subject [Object]
          # @return [String, nil]
          def symbol_word subject
            return nil unless subject.is_a?(::Parser::AST::Node)

            # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
            return nil unless %i[sym str].include?(subject.type)

            # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
            subject.children.first.to_s
          end

          # Forwardable's def_delegator/def_delegators define real methods
          # whose behavior - including return type - comes from the method
          # they forward to. Map them to DelegatedMethod pins, which resolve
          # the receiver and the forwarded method lazily.
          #
          # @return [void]
          def process_def_delegators
            receiver_word = symbol_word(node.children[2])
            return if receiver_word.nil?

            receiver_chain = delegation_receiver_chain(receiver_word)
            if node.children[1] == :def_delegator
              receiver_method_name = symbol_word(node.children[3])
              return if receiver_method_name.nil?

              name = symbol_word(node.children[4]) || receiver_method_name
              push_delegated_method(name, receiver_method_name, receiver_chain)
            else
              (node.children[3..] || []).each do |method_node|
                word = symbol_word(method_node)
                next if word.nil?

                push_delegated_method(word, word, receiver_chain)
              end
            end
          end

          # @param word [String] the delegation target, e.g. "@records" or "records"
          # @return [Source::Chain]
          def delegation_receiver_chain word
            link = if word.start_with?('@@')
                     Source::Chain::ClassVariable.new(word)
                   elsif word.start_with?('@')
                     Source::Chain::InstanceVariable.new(word, node, get_node_location(node))
                   else
                     Source::Chain::Call.new(word, get_node_location(node))
                   end
            Source::Chain.new([link])
          end

          # @param name [String]
          # @param receiver_method_name [String]
          # @param receiver_chain [Source::Chain]
          # @return [void]
          def push_delegated_method name, receiver_method_name, receiver_chain
            pins.push Solargraph::Pin::DelegatedMethod.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name,
              receiver: receiver_chain,
              receiver_method_name: receiver_method_name,
              scope: region.scope || :instance,
              visibility: region.visibility,
              comments: comments_for(node),
              source: :parser
            )
          end

          # @return [void]
          def process_visibility
            node => [:send, _, Symbol => visibility, *args]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            if args.empty?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, visibility)
            else
              # @sg-ignore Need to add nil check here
              args.each do |child|
                if child in ::Parser::AST::Node[:sym | :str, Symbol | String => value, *]
                  name = value.to_s
                  matches = pins.select { |pin| pin.is_a?(Pin::Method) && pin.name == name && pin.namespace == region.closure.full_context.namespace && pin.context.scope == (region.scope || :instance) }
                  matches.each do |pin|
                    # @todo Smelly instance variable access
                    pin.instance_variable_set(:@visibility, visibility)
                  end
                else
                  process_children region.update(visibility: visibility)
                end
              end
            end
          end

          # @return [void]
          def process_attribute
            node => [:send, _, Symbol => attr_method, *args]

            # @sg-ignore Need to add nil check here
            args.each do |a|
              # s(:sym, name) or s(:str, name); attr_reader(*X) passes s(:splat, s(:const, nil, :X))
              attr_name = (a in [_, value, *]) ? value : nil # rubocop:disable Style/RedundantParentheses
              loc = get_node_location(node)
              clos = region.closure
              cmnt = comments_for(node)
              if %i[attr_reader attr_accessor].include?(attr_method)
                pins.push Solargraph::Pin::Method.new(
                  location: loc,
                  closure: clos,
                  name: attr_name.to_s,
                  comments: cmnt,
                  scope: region.scope || :instance,
                  visibility: region.visibility,
                  attribute: true,
                  source: :parser
                )
              end
              next unless %i[attr_writer attr_accessor].include?(attr_method)
              method_pin = Solargraph::Pin::Method.new(
                location: loc,
                closure: clos,
                name: "#{attr_name}=",
                comments: cmnt,
                scope: region.scope || :instance,
                visibility: region.visibility,
                attribute: true,
                source: :parser
              )
              pins.push method_pin
              method_pin.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pins.last,
                                                            source: :parser)
              if method_pin.return_type.defined?
                pins.last.docstring.add_tag YARD::Tags::Tag.new(:param, '',
                                                                pins.last.return_type.items.map(&:rooted_tags), 'value')
              end
            end
          end

          # Process an ActiveSupport +class_attribute+ declaration.
          #
          # +class_attribute :name+ generates a singleton reader, writer and
          # predicate plus, unless disabled by options, an instance reader,
          # writer and predicate. The accessors are created at run time, so
          # without pins for them every class that calls +class_attribute+
          # loses its configuration API.
          #
          # @return [void]
          def process_class_attribute
            options = class_attribute_options
            instance_accessor = boolean_option options, 'instance_accessor', true
            instance_reader = boolean_option options, 'instance_reader', instance_accessor
            instance_writer = boolean_option options, 'instance_writer', instance_accessor
            instance_predicate = boolean_option options, 'instance_predicate', true
            node.children[2..].each do |a|
              next unless Parser.is_ast_node?(a) && %i[sym str].include?(a.type)
              name = a.children[0].to_s
              next if name.empty?
              pins.push build_class_attribute_pin name, scope: :class
              pins.push build_class_attribute_pin "#{name}=", scope: :class, writer: true
              pins.push build_class_attribute_pin "#{name}?", scope: :class if instance_predicate
              if instance_reader
                pins.push build_class_attribute_pin name, scope: :instance
                pins.push build_class_attribute_pin "#{name}?", scope: :instance if instance_predicate
              end
              pins.push build_class_attribute_pin "#{name}=", scope: :instance, writer: true if instance_writer
            end
          end

          # The literal keyword arguments passed to a +class_attribute+ call.
          # Values which cannot be evaluated statically are ignored.
          #
          # @return [Hash{String => AST::Node}]
          def class_attribute_options
            hash = node.children[-1]
            return {} unless Parser.is_ast_node?(hash) && hash.type == :hash
            hash.children.each_with_object({}) do |pair, result|
              next unless Parser.is_ast_node?(pair) && pair.type == :pair
              key = pair.children[0]
              next unless Parser.is_ast_node?(key) && %i[sym str].include?(key.type)
              result[key.children[0].to_s] = pair.children[1]
            end
          end

          # @param options [Hash{String => AST::Node}]
          # @param name [String]
          # @param default [Boolean]
          # @return [Boolean]
          def boolean_option options, name, default
            value = options[name]
            return default unless Parser.is_ast_node?(value)
            # rubocop:disable Lint/BooleanSymbol -- these are AST node types
            return true if value.type == :true
            return false if value.type == :false
            # rubocop:enable Lint/BooleanSymbol
            default
          end

          # @param name [String]
          # @param scope [Symbol] :class or :instance
          # @param writer [Boolean]
          # @return [Pin::Method]
          def build_class_attribute_pin name, scope:, writer: false
            pin = Pin::Method.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name,
              comments: comments_for(node),
              scope: scope,
              visibility: region.visibility,
              attribute: true,
              source: :parser
            )
            pin.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pin, source: :parser) if writer
            pin
          end

          # @return [void]
          def process_include
            node => [:send, _, _, *args]
            return unless args in [::AST::Node[:const, *], *]

            cp = region.closure
            # @sg-ignore Need to add nil check here
            args.each do |i|
              type = region.scope == :class ? Pin::Reference::Extend : Pin::Reference::Include
              pins.push type.new(
                location: get_node_location(i),
                closure: cp,
                name: unpack_name(i),
                source: :parser
              )
            end
          end

          # @return [void]
          def process_prepend
            node => [:send, _, _, *args]
            return unless args in [::AST::Node[:const, *], *]

            cp = region.closure
            # @sg-ignore Need to add nil check here
            args.each do |i|
              pins.push Pin::Reference::Prepend.new(
                location: get_node_location(i),
                closure: cp,
                name: unpack_name(i),
                source: :parser
              )
            end
          end

          # Process mixins called on an explicit receiver, e.g.,
          # +Object.prepend(self)+ in ActiveSupport or
          # +Integer.prepend ActiveSupport::NumericWithFormat+. Without this,
          # gems that extend core classes this way lose every method they
          # share with Object, Module, Integer, etc.
          #
          # @param keyword [::Symbol] one of :include, :extend, :prepend
          # @return [void]
          def process_qualified_mixin keyword
            reference_class = {
              include: Pin::Reference::Include,
              extend: Pin::Reference::Extend,
              prepend: Pin::Reference::Prepend
            }[keyword]
            return if reference_class.nil?
            receiver = node.children[0]
            target = unpack_name(receiver)
            return if target.nil? || target.empty?
            closure = Pin::Namespace.new(location: get_node_location(receiver), name: target, source: :parser)
            node.children[2..].each do |arg|
              next unless Parser.is_ast_node?(arg)
              name = if arg.type == :self
                       region.closure&.full_context&.namespace
                     elsif arg.type == :const
                       unpack_name(arg)
                     end
              next if name.nil? || name.empty?
              pins.push reference_class.new(
                location: get_node_location(arg),
                closure: closure,
                name: name,
                source: :parser
              )
            end
          end

          # @return [void]
          def process_extend
            node => [:send, _, _, *args]

            # @sg-ignore Need to add nil check here
            args.each do |i|
              loc = get_node_location(node)
              if i.type == :self
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: region.closure.full_context.namespace,
                  source: :parser
                )
              else
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: unpack_name(i),
                  source: :parser
                )
              end
            end
          end

          # @return [void]
          def process_require
            # require 'path' - s(:send, nil, :require, s(:str, path))
            return unless node in [:send, _, _, ::AST::Node[:str, String => value, *], *]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            path = value.to_s
            pins.push Pin::Reference::Require.new(get_node_location(node), path, source: :parser)
          end

          # @return [void]
          def process_autoload
            # autoload :Name, 'path' - s(:send, nil, :autoload, s(:sym, name), s(:str, path))
            return unless node in [:send, _, _, _, ::AST::Node[:str, String => value, *], *]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            path = value.to_s
            pins.push Pin::Reference::Require.new(get_node_location(node), path, source: :parser)
          end

          # @return [void]
          def process_module_function
            node => [:send, _, _, *args]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            if args.empty?
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, :module_function)
            elsif args in [[:sym | :str, *], *]
              # @sg-ignore Need to add nil check here
              args.each do |x|
                cn = (x in [_, value, *]) ? value.to_s : '' # rubocop:disable Style/RedundantParentheses
                # @type [Pin::Method, nil]
                ref = pins.find { |p| p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == cn }
                next if ref.nil?
                pins.delete ref
                mm = Solargraph::Pin::Method.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  parameters: ref.parameters,
                  comments: ref.comments,
                  scope: :class,
                  visibility: :public,
                  node: ref.node,
                  source: :parser
                )
                cm = Solargraph::Pin::Method.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  parameters: ref.parameters,
                  comments: ref.comments,
                  scope: :instance,
                  visibility: :private,
                  node: ref.node,
                  source: :parser
                )
                pins.push mm, cm
                ivars.select { |pin| pin.is_a?(Pin::InstanceVariable) && pin.closure.path == ref.path }.each do |ivar|
                  ivars.delete ivar
                  ivars.push Solargraph::Pin::InstanceVariable.new(
                    location: ivar.location,
                    closure: cm,
                    name: ivar.name,
                    comments: ivar.comments,
                    assignment: ivar.assignment,
                    source: :parser
                  )
                  ivars.push Solargraph::Pin::InstanceVariable.new(
                    location: ivar.location,
                    closure: mm,
                    name: ivar.name,
                    comments: ivar.comments,
                    assignment: ivar.assignment,
                    source: :parser
                  )
                end
              end
            elsif args in [::Parser::AST::Node[:def, *] => def_node, *]
              NodeProcessor.process def_node, region.update(visibility: :module_function), pins, locals, ivars
            end
          end

          # @return [void]
          def process_private_constant
            return unless node in [:send, _, _, [:sym | :str, Symbol | String => value, *], *]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            cn = value.to_s
            ref = pins.select do |p|
              [Solargraph::Pin::Namespace,
               Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn
            end.first
            # HACK: Smelly instance variable access
            ref&.instance_variable_set(:@visibility, :private)
          end

          # @return [void]
          def process_alias_method
            # alias_method :new, :old - s(:send, nil, :alias_method, s(:sym, new), s(:sym, old))
            # only reached when both arguments are sym nodes (see #process)
            node => [:send, _, _, [_, Symbol => new_name, *], [_, Symbol => original, *], *]

            get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: region.closure,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name: new_name.to_s,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              original: original.to_s,
              scope: region.scope || :instance,
              source: :parser
            )
          end

          # @return [Boolean]
          def process_private_class_method
            if node in [:send, _, _, [:sym | :str, Symbol | String => value, *], *]
              ref = pins.select do |p|
                # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                p.is_a?(Pin::Method) && p.namespace == region.closure.full_context.namespace && p.name == value.to_s
              end.first
              # HACK: Smelly instance variable access
              ref&.instance_variable_set(:@visibility, :private)
              false
            else
              process_children region.update(scope: :class, visibility: :private)
              true
            end
          end
        end
      end
    end
  end
end
