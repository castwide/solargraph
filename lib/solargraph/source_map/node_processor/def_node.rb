module Solargraph
  class SourceMap
    module NodeProcessor
      class DefNode < Base
        def process
          loc = get_node_location(node)
          methpin = Solargraph::Pin::Method.new(
            location: get_node_location(node),
            closure: region.closure,
            name: node.children[0].to_s,
            comments: comments_for(node),
            scope: region.scope || (region.closure.is_a?(Pin::Singleton) ? :class : :instance),
            visibility: region.visibility,
            args: method_args,
            node: node
          )
          if methpin.name == 'initialize' and methpin.scope == :instance
            pins.push Solargraph::Pin::Method.new(
              location: methpin.location,
              closure: methpin.closure,
              name: 'new',
              comments: methpin.comments,
              scope: :class,
              args: methpin.parameters
            )
            # @todo Smelly instance variable access.
            pins.last.instance_variable_set(:@return_type, ComplexType.try_parse('self'))
            pins.push methpin
            # @todo Smelly instance variable access.
            methpin.instance_variable_set(:@visibility, :private)
          elsif region.visibility == :module_function
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
          process_children region.update(closure: methpin, scope: methpin.scope)
        end
      end
    end
  end
end
