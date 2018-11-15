module Solargraph
  class SourceMap
    module NodeProcessor
      class SendNode < Base
        def process
          if node.children[0].nil?
            if [:private, :public, :protected].include?(node.children[1])
              # @todo Smelly instance variable access
              region.instance_variable_set(:@visibility, node.children[1])
            elsif [:attr_reader, :attr_writer, :attr_accessor].include?(node.children[1])
              node.children[2..-1].each do |a|
                if node.children[1] == :attr_reader || node.children[1] == :attr_accessor
                  pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}", comments_for(node), :reader, region.scope, region.visibility)
                end
                if node.children[1] == :attr_writer || node.children[1] == :attr_accessor
                  pins.push Solargraph::Pin::Attribute.new(get_node_location(node), region.namespace, "#{a.children[0]}=", comments_for(node), :writer, region.scope, region.visibility)
                end
              end
            elsif node.children[1] == :require && node.children[2].kind_of?(AST::Node) && node.children[2].type == :str
              pins.push Pin::Reference::Require.new(get_node_location(node), node.children[2].children[0].to_s)
            end
          end
        end
      end
    end
  end
end
