module Solargraph
  class SourceMap
    module NodeProcessor
      class SendNode < Base
        def process
          if node.children[0].nil?
            if [:private, :public, :protected].include?(node.children[1])
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, node.children[1])
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
            if node.children[1] == :attr_reader || node.children[1] == :attr_accessor
              pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}", comments_for(node), :reader, region.scope, region.visibility)
            end
            if node.children[1] == :attr_writer || node.children[1] == :attr_accessor
              pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}=", comments_for(node), :writer, region.scope, region.visibility)
            end
          end
        end

        def process_include
          if node.children[2].kind_of?(AST::Node) && node.children[2].type == :const
            node.children[2..-1].each do |i|
              nspin = pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == region.namespace}.last
              unless nspin.nil?
                pins.push Pin::Reference::Include.new(get_node_location(node), nspin.path, unpack_name(i))
              end
            end
          end
        end

        def process_extend
          node.children[2..-1].each do |i|
            nspin = pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == region.namespace}.last
            unless nspin.nil?
              ref = nil
              if i.type == :self
                ref = Pin::Reference::Extend.new(get_node_location(node), nspin.path, nspin.path)
              elsif i.type == :const
                ref = Pin::Reference::Extend.new(get_node_location(node), nspin.path, unpack_name(i))
              end
              pins.push ref unless ref.nil?
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
            node.children[2..-1].each do |x|
              cn = x.children[0].to_s
              ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == region.namespace && p.name == cn}.first
              unless ref.nil?
                pins.delete ref
                mm = Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, :class, :public, ref.parameters, ref.node)
                cm = Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, :instance, :private, ref.parameters, ref.node)
                pins.push mm, cm
                pins.select{|pin| pin.kind == Pin::INSTANCE_VARIABLE and pin.context == ref.context}.each do |ivar|
                  pins.delete ivar
                  pins.push Solargraph::Pin::InstanceVariable.new(ivar.location, ivar.namespace, ivar.name, ivar.comments, ivar.signature, ivar.instance_variable_get(:@literal), mm)
                  pins.push Solargraph::Pin::InstanceVariable.new(ivar.location, ivar.namespace, ivar.name, ivar.comments, ivar.signature, ivar.instance_variable_get(:@literal), cm)
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
                pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.signature, ref.return_type, ref.context, :private)
              else
                # pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.type, :private, (ref.superclass_reference.nil? ? nil : ref.superclass_reference.name))
                pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.type, :private)
              end
            end
          end
        end

        def process_alias_method
          pin = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.name == node.children[3].children[0].to_s && p.namespace == region.namespace && p.scope == region.scope}.first
          if pin.nil?
            pins.push Solargraph::Pin::MethodAlias.new(get_node_location(node), region.namespace, node.children[2].children[0].to_s, region.scope, node.children[3].children[0].to_s)
          else
            if pin.is_a?(Solargraph::Pin::Method)
              pins.push Solargraph::Pin::Method.new(get_node_location(node), pin.namespace, node.children[2].children[0].to_s, comments_for(node) || pin.comments, pin.scope, pin.visibility, pin.parameters, pin.node)
            elsif pin.is_a?(Solargraph::Pin::Attribute)
              pins.push Solargraph::Pin::Attribute.new(get_node_location(node), pin.namespace, node.children[2].children[0].to_s, comments_for(node) || pin.comments, pin.access, pin.scope, pin.visibility)
            end
          end
        end

        def process_private_class_method
          if node.children[2].type == :sym || node.children[2].type == :str
            ref = pins.select{|p| [Solargraph::Pin::Method, Solargraph::Pin::Attribute].include?(p.class) && p.namespace == region.namespace && p.name == node.children[2].children[0].to_s}.first
            unless ref.nil?
              pins.delete ref
              pins.push Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, ref.scope, :private, ref.parameters, ref.node)
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
