module Solargraph
  module Pin
    class Method < Base
      attr_reader :scope
      attr_reader :visibility

      def initialize source, node, namespace, scope, visibility
        super(source, node, namespace)
        @scope = scope
        @visibility = visibility
      end

      def name
        @name ||= "#{node.children[(node.type == :def ? 0 : 1)]}"
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def kind
        Solargraph::Suggestion::METHOD
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          @return_type = tag.types[0] unless tag.nil? or tag.types.nil?
        end
        @return_type
      end

      def parameters
        @parameters ||= get_method_args
      end

      private

      # @return [Array<String>]
      def get_method_args
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
            args.push "#{c.children[0]} = #{source.code_for(c.children[1])}"
          elsif c.type == :kwarg
            args.push "#{c.children[0]}:"
          elsif c.type == :kwoptarg
            args.push "#{c.children[0]}: #{source.code_for(c.children[1])}"
          end
        }
        args
      end
    end
  end
end
