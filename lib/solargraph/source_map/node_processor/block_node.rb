module Solargraph
  class SourceMap
    module NodeProcessor
      class BlockNode < Base
        def process
          here = get_node_start_position(node)
          pins.push Solargraph::Pin::Block.new(
            location: get_node_location(node),
            closure: region.closure,
            receiver: node.children[0],
            comments: comments_for(node),
            scope: region.scope || region.closure.context.scope,
            args: method_args
          )
          process_children region.update(closure: pins.last)
        end

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
