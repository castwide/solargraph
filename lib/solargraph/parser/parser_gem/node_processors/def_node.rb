# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class DefNode < Parser::NodeProcessor::Base
          def process
            name = node.children[0].to_s
            scope = region.scope || (region.closure.is_a?(Pin::Singleton) ? :class : :instance)
            methpin = Solargraph::Pin::Method.new(
              location: get_node_location(node),
              closure: region.closure,
              name: name,
              comments: comments_for(node),
              scope: scope,
              visibility: scope == :instance && name == 'initialize' ? :private : region.visibility,
              node: node
            )
            if region.visibility == :module_function
              pins.push Solargraph::Pin::Method.new(
                location: methpin.location,
                closure: methpin.closure,
                name: methpin.name,
                comments: methpin.comments,
                scope: :class,
                visibility: :public,
                parameters: methpin.parameters,
                node: methpin.node
              )
              pins.push Solargraph::Pin::Method.new(
                location: methpin.location,
                closure: methpin.closure,
                name: methpin.name,
                comments: methpin.comments,
                scope: :instance,
                visibility: :private,
                parameters: methpin.parameters,
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
end
