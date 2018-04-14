module Solargraph
  module Pin
    class BaseVariable < Base
      attr_reader :signature

      attr_reader :context

      def initialize location, namespace, name, docstring, signature, literal, context
        super(location, namespace, name, docstring)
        @signature = signature
        @literal = literal
        @context = context
      end

      def scope
        @scope ||= (context.kind == Pin::METHOD and context.scope == :instance ? :instance : :class)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      def return_type
        if @return_type.nil?
          if !docstring.nil?
            tag = docstring.tag(:type)
            @return_type = tag.types[0] unless tag.nil?
          else
            @return_type = @literal
          end
        end
        @return_type
      end

      # def calculated_signature
      #   # if @calculated_signature.nil?
      #   #   if signature.empty?
      #   #     type = infer_literal_node_type(assignment_node)
      #   #     @calculated_signature = "#{type}.new" unless type.nil?
      #   #   end
      #   #   @calculated_signature ||= signature
      #   # end
      #   # @calculated_signature
      # end

      # @param api_map [Solargraph::ApiMap]
      # def resolve api_map
      #   if return_type.nil? and !@tried_to_resolve_return_type
      #     @tried_to_detect_return_type = true
      #     return nil if signature.nil? or signature.empty? or signature == name or signature.split('.').first.strip == name
      #     # @todo This should be able to resolve signatures that start with local variables
      #     macro_type = nil
      #     # pin = api_map.tail_pin(signature, namespace, :class, [:public, :private, :protected])
      #     # unless pin.nil? or !pin.method?
      #     #   macro_type = get_return_type_from_macro(pin, assignment_node)
      #     # end
      #     @return_type = macro_type || api_map.infer_type(signature, namespace, scope: :class)
      #   end
      # end

      def nil_assignment?
        return_type == 'NilClass'
      end

      def variable?
        true
      end

      def signature
        if @signature.nil? and !return_type.nil?
          # @todo This is a shortcut that assumes the return_type does not
          #   reference a complex type like Class<String>.
          @signature = "#{return_type}.new"
        end
        @signature
      end

      private

      def get_call_arguments node
        return get_call_arguments(node.children[1]) if [:ivasgn, :cvasgn, :lvasgn].include?(node.type)
        return [] unless node.type == :send
        result = []
        node.children[2..-1].each do |c|
          result.push unpack_name(c)
        end
        result
      end

      def get_return_type_from_macro method_pin, call_node
        return nil if method_pin.docstring.nil?
        type = nil
        all = YARD::Docstring.parser.parse(method_pin.docstring.all).directives
        macro = all.select{|m| m.tag.tag_name == 'macro'}.first
        return nil if macro.nil?
        macstring = YARD::Docstring.parser.parse(macro.tag.text).to_docstring
        rt = macstring.tag(:return)
        unless rt.nil? or rt.types.nil?
          args = get_call_arguments(call_node)
          type = "#{args[rt.types[0][1..-1].to_i-1]}"
        end
        type
      end
    end
  end
end
