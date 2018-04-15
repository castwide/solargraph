module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      include Localized

      def initialize location, namespace, name, docstring, assignment, literal, context, block, presence
        super(location, namespace, name, docstring, assignment, literal, context)
        @block = block
        @presence = presence
        # @tree = []
        # ancestors.each do |parent|
        #   if [:block, :def, :defs, :class, :module, :source].include? parent.type
        #     @tree.push parent
        #   end
        # end
      end

      def kind
        Pin::LOCAL_VARIABLE
      end

      # def visible_from? n
      #   parents = [n] + (source.tree_for(n) || [])
      #   parents.each do |p|
      #     return true if @tree[0] == p
      #     return false if [:def, :defs, :class, :module].include?(p.type)
      #   end
      #   false
      # end      
    end
  end
end
