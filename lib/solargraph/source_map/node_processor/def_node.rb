module Solargraph
  class SourceMap
    module NodeProcessor
      class DefNode < Base
        def process
          # methpin = Solargraph::Pin::Method.new(get_node_location(node), region.namespace, node.children[0].to_s, comments_for(node), region.scope, region.visibility, method_args, node)
          loc = get_node_location(node)
          methpin = Solargraph::Pin::Method.new(
            location: get_node_location(node),
            closure: closure_pin(loc.range.start),
            name: node.children[0].to_s,
            comments: comments_for(node),
            scope: region.scope,
            visibility: region.visibility,
            args: method_args
          )
          if methpin.name == 'initialize' and methpin.scope == :instance
            # pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, 'new', methpin.comments, :class, :public, methpin.parameters, nil)
            pins.push Solargraph::Pin::Method.new(
              location: methpin.location,
              closure: methpin.closure,
              name: 'new',
              comments: methpin.comments,
              scope: :class,
              args: methpin.parameters
            )
            # @todo Smelly instance variable access.
            pins.last.instance_variable_set(:@return_complex_type, ComplexType.parse(methpin.namespace))
            pins.push methpin
            # pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, methpin.scope, :private, methpin.parameters, methpin.node)
            methpin.instance_variable_set(:@visibility, :private)
          elsif region.visibility == :module_function
            # pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, :class, :public, methpin.parameters, methpin.node)
            # pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, :instance, :private, methpin.parameters, methpin.node)
            pins.push Solargraph::Pin::Method.new(
              location: methpin.location,
              closure: methpin.closure,
              name: methpin.name,
              comments: methpin.comments,
              scope: :class,
              visibility: :public,
              args: methpin.parameters,
              node: methpin.node
            )
            pins.push Solargraph::Pin::Method.new(
              location: methpin.location,
              closure: methpin.closure,
              name: methpin.name,
              comments: methpin.comments,
              scope: :instance,
              visibility: :private,
              args: methpin.parameters,
              node: methpin.node
            )
          else
            pins.push methpin
          end
          process_children
        end

        private

        def method_args
          return [] if node.nil?
          list = nil
          args = []
          node.children.each { |c|
            if c.kind_of?(AST::Node) and c.type == :args
              list = c
              break
            end
          }
          return args if list.nil?
          list.children.each { |c|
            if c.type == :arg
              args.push c.children[0].to_s
            elsif c.type == :restarg
              args.push "*#{c.children[0]}"
            elsif c.type == :optarg
              args.push "#{c.children[0]} = #{region.code_for(c.children[1])}"
            elsif c.type == :kwarg
              args.push "#{c.children[0]}:"
            elsif c.type == :kwoptarg
              args.push "#{c.children[0]}: #{region.code_for(c.children[1])}"
            elsif c.type == :blockarg
              args.push "&#{c.children[0]}"
            end
          }
          args
        end
      end
    end
  end
end
