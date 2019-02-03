module Solargraph
  class SourceMap
    module NodeProcessor
      class SendNode < Base
        def process
          if node.children[0].nil?
            if [:private, :public, :protected].include?(node.children[1])
              if (node.children.length > 2)
                node.children[2..-1].each do |child|
                  next unless child.is_a?(AST::Node) && (child.type == :sym || child.type == :str)
                  name = child.children[0].to_s
                  matches = pins.select{ |pin| [Pin::METHOD, Pin::ATTRIBUTE].include?(pin.kind) && pin.name == name && pin.namespace == region.namespace && pin.context.scope == region.scope }
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
            elsif node.children[1] == :private_class_method && node.children[2].kind_of?(AST::Node)
              # Processing a private class can potentially handle children on its own
              return if process_private_class_method
            end
          end
          process_children
        end

        private

        def process_attribute
          node.children[2..-1].each do |a|
            loc = get_node_location(node)
            clos = closure_pin(loc.range.start)
            if node.children[1] == :attr_reader || node.children[1] == :attr_accessor
              # pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}", comments_for(node), :reader, region.scope, region.visibility)
              pins.push Solargraph::Pin::Attribute.new(
                location: loc,
                closure: clos,
                name: a.children[0].to_s,
                comments: comments_for(node),
                access: :reader,
                scope: region.scope || :instance,
                visibility: region.visibility
              )
            end
            if node.children[1] == :attr_writer || node.children[1] == :attr_accessor
              # pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}=", comments_for(node), :writer, region.scope, region.visibility)
              pins.push Solargraph::Pin::Attribute.new(
                location: loc,
                closure: clos,
                name: "#{a.children[0]}=",
                comments: comments_for(node),
                access: :writer,
                scope: region.scope || :instance,
                visibility: region.visibility
              )
            end
          end
        end

        def process_include
          if node.children[2].kind_of?(AST::Node) && node.children[2].type == :const
            cp = closure_pin(get_node_start_position(node))
            node.children[2..-1].each do |i|
              # nspin = pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == region.namespace}.last
              # unless nspin.nil?
                pins.push Pin::Reference::Include.new(
                  location: get_node_location(i),
                  closure: cp,
                  name: unpack_name(i)
                )
              # end
            end
          end
        end

        def process_extend
          node.children[2..-1].each do |i|
            # nspin = pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == region.namespace}.last
            # unless nspin.nil?
            #   ref = nil
            #   if i.type == :self
            #     ref = Pin::Reference::Extend.new(get_node_location(node), nspin.path, nspin.path)
            #   elsif i.type == :const
            #     ref = Pin::Reference::Extend.new(get_node_location(node), nspin.path, unpack_name(i))
            #   end
            #   pins.push ref unless ref.nil?
            # end
            loc = get_node_location(node)
            path_pin = named_path_pin(loc.range.start)
            closure = closure_pin(loc.range.start)
            if i.type == :self
              pins.push Pin::Reference::Extend.new(
                location: loc,
                closure: closure,
                name: path_pin.path
              )
            else
              pins.push Pin::Reference::Extend.new(
                location: loc,
                closure: closure,
                name: unpack_name(i)
              )
            end
          end
        end

        def process_require
          if node.children[2].kind_of?(AST::Node) && node.children[2].type == :str
            pins.push Pin::Reference::Require.new(get_node_location(node), node.children[2].children[0].to_s)
          end
        end

        def process_module_function
          if node.children[2].nil?
            # @todo Smelly instance variable access
            region.instance_variable_set(:@visibility, :module_function)
          elsif node.children[2].type == :sym || node.children[2].type == :str
            # @todo What to do about references?
            nspin = named_path_pin(get_node_start_position(node))
            clos = closure_pin(get_node_start_position(node))
            node.children[2..-1].each do |x|
              cn = x.children[0].to_s
              ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == nspin.path && p.name == cn}.first
              unless ref.nil?
                pins.delete ref
                mm = Solargraph::Pin::Method.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  comments: ref.comments,
                  scope: :class,
                  visibility: :public,
                  args: ref.parameters,
                  node: ref.node
                )
                cm = Solargraph::Pin::Method.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  comments: ref.comments,
                  scope: :instance,
                  visibility: :private,
                  args: ref.parameters,
                  node: ref.node)
                pins.push mm, cm
                pins.select{|pin| pin.kind == Pin::INSTANCE_VARIABLE && pin.closure.path == ref.path}.each do |ivar|
                  pins.delete ivar
                  pins.push Solargraph::Pin::InstanceVariable.new(
                    location: ivar.location,
                    closure: cm,
                    name: ivar.name,
                    comments: ivar.comments,
                    assignment: ivar.assignment,
                    scope: :instance
                  )
                  pins.push Solargraph::Pin::InstanceVariable.new(
                    location: ivar.location,
                    closure: mm,
                    name: ivar.name,
                    comments: ivar.comments,
                    assignment: ivar.assignment,
                    scope: :class
                  )
                end
              end
            end
          elsif node.children[2].type == :def
            NodeProcessor.process node.children[2], region.update(visibility: :module_function), pins
          end
        end

        def process_private_constant
          if node.children[2] && (node.children[2].type == :sym || node.children[2].type == :str)
            # @todo What to do about references?
            cn = node.children[2].children[0].to_s
            ref = pins.select{|p| [Solargraph::Pin::Namespace, Solargraph::Pin::Constant].include?(p.class) && p.namespace == region.namespace && p.name == cn}.first
            unless ref.nil?
              pins.delete ref
              # Might be either a namespace or constant
              if ref.kind == Pin::CONSTANT
                # pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.signature, ref.return_type, ref.context, :private)
                pins.push ref.class.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  comments: ref.comments,
                  visibility: :private
                )
                # @todo Smelly instance variable access
                pins.last.instance_variable_set(:@return_complex_type, ref.return_type)
              else
                # pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.type, :private, (ref.superclass_reference.nil? ? nil : ref.superclass_reference.name))
                # pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.type, :private)
                pins.push ref.class.new(
                  location: ref.location,
                  closure: ref.closure,
                  name: ref.name,
                  comments: ref.comments,
                  type: ref.type,
                  visibility: :private
                )
              end
            end
          end
        end

        def process_alias_method
          loc = get_node_location(node)
          pin = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.name == node.children[3].children[0].to_s && p.namespace == region.namespace && p.scope == region.scope}.first
          if pin.nil?
            # pins.push Solargraph::Pin::MethodAlias.new(get_node_location(node), region.namespace, node.children[2].children[0].to_s, region.scope, node.children[3].children[0].to_s)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: get_node_location(node),
              closure: closure_pin(loc.range.start),
              name: node.children[2].children[0].to_s,
              original: node.children[3].children[0].to_s
            )
          else
            if pin.is_a?(Solargraph::Pin::Method)
              # pins.push Solargraph::Pin::Method.new(get_node_location(node), pin.namespace, node.children[2].children[0].to_s, comments_for(node) || pin.comments, pin.scope, pin.visibility, pin.parameters, pin.node)
              pins.push Solargraph::Pin::Method.new(
                location: loc,
                closure: pin.closure,
                name: node.children[2].children[0].to_s,
                comments: comments_for(node) || pin.comments,
                scope: pin.scope,
                visibility: pin.visibility
              )
            elsif pin.is_a?(Solargraph::Pin::Attribute)
              # pins.push Solargraph::Pin::Attribute.new(get_node_location(node), pin.namespace, node.children[2].children[0].to_s, comments_for(node) || pin.comments, pin.access, pin.scope, pin.visibility)
              pins.push Solargraph::Pin::Attribute.new(
                location: loc,
                closure: pin.closure,
                name: node.children[2].children[0].to_s,
                comments: comments_for(node) || pin.comments,
                scope: pin.scope,
                visibility: pin.visibility,
                access: pin.access
              )
            end
          end
        end

        def process_private_class_method
          if node.children[2].type == :sym || node.children[2].type == :str
            ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == region.namespace && p.name == node.children[2].children[0].to_s}.first
            unless ref.nil?
              pins.delete ref
              # pins.push Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, ref.scope, :private, ref.parameters, ref.node)
              pins.push Solargraph::Pin::Method.new(
                location: ref.location,
                closure: ref.closure,
                name: ref.name,
                comments: ref.comments,
                scope: ref.scope,
                visibility: :private,
                args: ref.parameters,
                node: ref.node
              )
            end
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
