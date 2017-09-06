module Solargraph
  class ApiMap
    class AttrPin
      attr_reader :node

      def initialize node
        @node = node
      end

      def suggestions
        @suggestions ||= generate_suggestions
      end

      private

      def generate_suggestions
        suggestions = []
        c = node
        if c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_reader
          c.children[2..-1].each { |x|
            suggestions.push Suggestion.new(x.children[0], kind: Suggestion::FIELD) if x.type == :sym
          }
        elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_writer
          c.children[2..-1].each { |x|
            suggestions.push Suggestion.new("#{x.children[0]}=", kind: Suggestion::FIELD) if x.type == :sym
          }
        elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_accessor
          c.children[2..-1].each { |x|
            suggestions.push Suggestion.new(x.children[0], kind: Suggestion::FIELD) if x.type == :sym
            suggestions.push Suggestion.new("#{x.children[0]}=", insert: "#{x.children[0]} = ", kind: Suggestion::FIELD) if x.type == :sym
          }
        end
        suggestions
      end
    end
  end
end
