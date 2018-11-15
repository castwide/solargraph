module Solargraph
  class SourceMap
    module NodeProcessor
      class DefsNode < Base
        def process
          s_visi = region.visibility
          s_visi = :public if s_visi == :module_function || region.scope != :class
          if node.children[0].is_a?(AST::Node) && node.children[0].type == :self
            dfqn = region.namespace
          else
            dfqn = unpack_name(node.children[0])
          end
          unless dfqn.nil?
            pins.push Solargraph::Pin::Method.new(get_node_location(node), dfqn, "#{node.children[1]}", comments_for(node), :class, s_visi, method_args, node)
            process_children region.update(namespace: dfqn)
          end
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
              args.push "#{c.children[0]} = #{code_for(c.children[1])}"
            elsif c.type == :kwarg
              args.push "#{c.children[0]}:"
            elsif c.type == :kwoptarg
              args.push "#{c.children[0]}: #{code_for(c.children[1])}"
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
