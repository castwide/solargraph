module Solargraph
  class ApiMap
    class MethodPin
      attr_reader :node
      attr_reader :namespace
      attr_reader :scope
      attr_reader :visibility
      attr_reader :docstring
      
      def initialize node, namespace, scope, visibility, docstring
        @node = node
        @namespace = namespace
        @scope = scope
        @visibility = visibility
        @docstring = docstring
      end

      def suggestion(api_map)
        @suggestion ||= generate_suggestion(api_map)
      end

      private

      def generate_suggestion(api_map)
        i = node.type == :def ? 0 : 1
        label = "#{node.children[i]}"
        Suggestion.new(label, insert: node.children[i].to_s.gsub(/=/, ' = '), kind: Suggestion::METHOD, documentation: docstring, detail: namespace, arguments: get_method_args(api_map))
      end

      # @return [Array<String>]
      def get_method_args(api_map)
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
          elsif c.type == :optarg
            args.push "#{c.children[0]} = #{api_map.code_for(c.children[1])}"
          elsif c.type == :kwarg
            args.push "#{c.children[0]}:"
          elsif c.type == :kwoptarg
            args.push "#{c.children[0]}: #{api_map.code_for(c.children[1])}"
          end
        }
        args
      end
    end
  end
end
