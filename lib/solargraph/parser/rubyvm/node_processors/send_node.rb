# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class SendNode < Parser::NodeProcessor::Base
          include Rubyvm::NodeMethods

          def process
            if [:private, :public, :protected].include?(node.children[0])
              if (node.type == :FCALL && node.children.last.children.length > 1)
                node.children.last.children[0..-2].each do |child|
                  # next unless child.is_a?(AST::Node) && (child.type == :sym || child.type == :str)
                  next unless child.type == :LIT || child.type == :STR
                  name = child.children[0].to_s
                  matches = pins.select{ |pin| pin.is_a?(Pin::BaseMethod) && pin.name == name && pin.namespace == region.closure.full_context.namespace && pin.context.scope == (region.scope || :instance)}
                  matches.each do |pin|
                    # @todo Smelly instance variable access
                    pin.instance_variable_set(:@visibility, node.children[0])
                  end
                end
              else
                # @todo Smelly instance variable access
                region.instance_variable_set(:@visibility, node.children[0])
              end
            elsif node.children[0] == :module_function
              process_module_function
            elsif node.children[0] == :require
              process_require
            elsif node.children[0] == :alias_method
              process_alias_method
            elsif node.children[0] == :private_class_method && Parser.is_ast_node?(node)
              # Processing a private class can potentially handle children on its own
              return if process_private_class_method
            elsif [:attr_reader, :attr_writer, :attr_accessor].include?(node.children[0])
              process_attribute
            elsif node.children[0] == :include
              process_include
            elsif node.children[0] == :extend
              process_extend
            elsif node.children[0] == :prepend
              process_include
            elsif node.children[0] == :private_constant
              process_private_constant
            end
            process_children
            return
            # @todo Get rid of legacy
            if node.children[0].nil?
              if [:private, :public, :protected].include?(node.children[1])
                if (node.children.length > 2)
                  node.children[2..-1].each do |child|
                    next unless child.is_a?(AST::Node) && (child.type == :sym || child.type == :str)
                    name = child.children[0].to_s
                    matches = pins.select{ |pin| pin.is_a?(Pin::BaseMethod) && pin.name == name && pin.namespace == region.closure.full_context.namespace && pin.context.scope == (region.scope || :instance)}
                    matches.each do |pin|
                      # @todo Smelly instance variable access
                      pin.instance_variable_set(:@visibility, node.children[1])
                    end
                  end
                else
                  # @todo Smelly instance variable access
                  region.instance_variable_set(:@visibility, node.children[1])
                end
              elsif node.children[1] == :module_function
                process_module_function
              elsif [:attr_reader, :attr_writer, :attr_accessor].include?(node.children[1])
                process_attribute
              elsif node.children[1] == :include
                process_include
              elsif node.children[1] == :extend
                process_extend
              elsif node.children[1] == :require
                process_require
              elsif node.children[1] == :private_constant
                process_private_constant
              elsif node.children[1] == :alias_method && node.children[2] && node.children[2] && node.children[2].type == :sym && node.children[3] && node.children[3].type == :sym
                process_alias_method
              elsif node.children[1] == :private_class_method && node.children[2].is_a?(AST::Node)
                # Processing a private class can potentially handle children on its own
                return if process_private_class_method
              end
            elsif node.children[1] == :require && node.children[0].to_s == '(const nil :Bundler)'
              pins.push Pin::Reference::Require.new(Solargraph::Location.new(region.filename, Solargraph::Range.from_to(0, 0, 0, 0)), 'bundler/require')
            end
            process_children
          end

          private

          # @return [void]
          def process_attribute
            return unless Parser.is_ast_node?(node.children[1])
            node.children[1].children[0..-2].each do |a|
              next unless a.type == :LIT
              loc = get_node_location(node)
              clos = region.closure
              cmnt = comments_for(node)
              if node.children[0] == :attr_reader || node.children[0] == :attr_accessor
                pins.push Solargraph::Pin::Attribute.new(
                  location: loc,
                  closure: clos,
                  name: a.children[0].to_s,
                  comments: cmnt,
                  access: :reader,
                  scope: region.scope || :instance,
                  visibility: region.visibility
                )
              end
              if node.children[0] == :attr_writer || node.children[0] == :attr_accessor
                pins.push Solargraph::Pin::Attribute.new(
                  location: loc,
                  closure: clos,
                  name: "#{a.children[0]}=",
                  comments: cmnt,
                  access: :writer,
                  scope: region.scope || :instance,
                  visibility: region.visibility
                )
              end
            end
          end

          # @return [void]
          def process_include
            return unless Parser.is_ast_node?(node.children.last)
            node.children.last.children[0..-2].each do |i|
              next unless [:COLON2, :COLON3, :CONST].include?(i.type)
              pins.push Pin::Reference::Include.new(
                location: get_node_location(i),
                closure: region.closure,
                name: unpack_name(i)
              )
            end
          end

          # @return [void]
          def process_extend
            return unless Parser.is_ast_node?(node.children.last)
            node.children.last.children[0..-2].each do |i|
              next unless [:COLON2, :COLON3, :CONST, :SELF].include?(i.type)
              loc = get_node_location(node)
              if i.type == :SELF
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: region.closure.full_context.namespace
                )
              else
                pins.push Pin::Reference::Extend.new(
                  location: loc,
                  closure: region.closure,
                  name: unpack_name(i)
                )
              end
            end
          end

          # @return [void]
          def process_require
            return unless Parser.is_ast_node?(node.children[1])
            node.children[1].children.each do |arg|
              next unless Parser.is_ast_node?(arg)
              if arg.type == :STR
                pins.push Pin::Reference::Require.new(get_node_location(arg), arg.children[0])
              end
            end
          end

          # @return [void]
          def process_module_function
            if node.type == :VCALL
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, :module_function)
            elsif node.children.last.children[0].type == :DEFN
              NodeProcessor.process node.children.last.children[0], region.update(visibility: :module_function), pins, locals
            else
              node.children.last.children[0..-2].each do |x|
                next unless [:LIT, :STR].include?(x.type)
                cn = x.children[0].to_s
                ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn}.first
                unless ref.nil?
                  pins.delete ref
                  mm = Solargraph::Pin::Method.new(
                    location: ref.location,
                    closure: ref.closure,
                    name: ref.name,
                    comments: ref.comments,
                    scope: :class,
                    visibility: :public,
                    parameters: ref.parameters,
                    node: ref.node
                  )
                  cm = Solargraph::Pin::Method.new(
                    location: ref.location,
                    closure: ref.closure,
                    name: ref.name,
                    comments: ref.comments,
                    scope: :instance,
                    visibility: :private,
                    parameters: ref.parameters,
                    node: ref.node)
                  pins.push mm, cm
                  pins.select{|pin| pin.is_a?(Pin::InstanceVariable) && pin.closure.path == ref.path}.each do |ivar|
                    pins.delete ivar
                    pins.push Solargraph::Pin::InstanceVariable.new(
                      location: ivar.location,
                      closure: cm,
                      name: ivar.name,
                      comments: ivar.comments,
                      assignment: ivar.assignment
                      # scope: :instance
                    )
                    pins.push Solargraph::Pin::InstanceVariable.new(
                      location: ivar.location,
                      closure: mm,
                      name: ivar.name,
                      comments: ivar.comments,
                      assignment: ivar.assignment
                      # scope: :class
                    )
                  end
                end
              end
            end
          end

          # @return [void]
          def process_private_constant
            node.children.last.children[0..-2].each do |child|
              if [:LIT, :STR].include?(child.type)
                cn = child.children[0].to_s
                ref = pins.select{|p| [Solargraph::Pin::Namespace, Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == cn}.first
                # HACK: Smelly instance variable access
                ref.instance_variable_set(:@visibility, :private) unless ref.nil?
              end
            end
          end

          # @return [void]
          def process_alias_method
            arr = node.children[1]
            return if arr.nil?
            first = arr.children[0]
            second = arr.children[1]
            return unless first && second && [:LIT, :STR].include?(first.type) && [:LIT, :STR].include?(second.type)
            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: region.closure,
              name: first.children[0].to_s,
              original: second.children[0].to_s,
              scope: region.scope || :instance
            )
          end

          # @return [Boolean]
          def process_private_class_method
            if node.children.last.children.first.type == :DEFN
              process_children region.update(scope: :class, visibility: :private)
              true
            else
              node.children.last.children[0..-2].each do |child|
                if child.type == :LIT && child.children.first.is_a?(::Symbol)
                  sym_name = child.children.first.to_s
                  ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == region.closure.full_context.namespace && p.name == sym_name}.first
                  # HACK: Smelly instance variable access
                  ref.instance_variable_set(:@visibility, :private) unless ref.nil?
                  false
                end
              end
            end
          end
        end
      end
    end
  end
end
