module Solargraph
  module Pin
    class Method < Base
      attr_reader :scope
      attr_reader :visibility
      
      def initialize location, namespace, name, docstring, scope, visibility
        super(location, namespace, name, docstring)
        @scope = scope
        @visibility = visibility
      #   super(source, node, namespace)
      #   @scope = scope
      #   @visibility = visibility
      #   # Exception for initialize methods
      #   if name == 'initialize' and scope == :instance
      #     @visibility = :private
      #   end
      #   @fully_resolved = false
      end

      def kind
        Solargraph::Pin::METHOD
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          if tag.nil?
            ol = docstring.tag(:overload)
            tag = ol.tag(:return) unless ol.nil?
          end
          @return_type = tag.types[0] unless tag.nil? or tag.types.nil?
        end
        @return_type
      end

      def parameters
        @parameters ||= get_method_args
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          unless docstring.nil?
            param_tags = docstring.tags(:param)
            unless param_tags.nil? or param_tags.empty?
              @documentation += "\n\n"
              @documentation += "Params:\n"
              lines = []
              param_tags.each do |p|
                l = "* #{p.name}"
                l += " [#{p.types.join(', ')}]" unless p.types.empty?
                l += " #{p.text}"
                lines.push l
              end
              @documentation += lines.join("\n")
            end
          end
        end
        @documentation
      end

      # @todo This method was temporarily migrated directly from Suggestion
      # @return [Array<String>]
      def params
        if @params.nil?
          @params = []
          return @params if docstring.nil?
          param_tags = docstring.tags(:param)
          unless param_tags.empty?
            param_tags.each do |t|
              txt = t.name.to_s
              txt += " [#{t.types.join(',')}]" unless t.types.nil? or t.types.empty?
              txt += " #{t.text}" unless t.text.nil? or t.text.empty?
              @params.push txt
            end
          end
        end
        @params
      end

      def resolve api_map
        if return_type.nil?
          sc = api_map.superclass_of(namespace)
          until sc.nil?
            sc_path = "#{sc}#{scope == :instance ? '#' : '.'}#{name}"
            sugg = api_map.get_path_suggestions(sc_path).first
            break if sugg.nil?
            @return_type = api_map.find_fully_qualified_namespace(sugg.return_type, sugg.namespace) unless sugg.return_type.nil?
            break unless @return_type.nil?
            sc = api_map.superclass_of(sc)
          end
        end
        unless return_type.nil? or @fully_resolved
          @fully_resolved = true
          @return_type = api_map.find_fully_qualified_namespace(@return_type, namespace)
        end
      end

      def method?
        true
      end

      private

      # @return [Array<String>]
      def get_method_args
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
            args.push "#{c.children[0]} = #{source.code_for(c.children[1])}"
          elsif c.type == :kwarg
            args.push "#{c.children[0]}:"
          elsif c.type == :kwoptarg
            args.push "#{c.children[0]}: #{source.code_for(c.children[1])}"
          elsif c.type == :blockarg
            args.push "&#{c.children[0]}"
          end
        }
        args
      end
    end
  end
end
