# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class ArgsNode < Parser::NodeProcessor::Base
          def process
            node.children[0].times do |i|
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: region.lvars[i].to_s,
                presence: region.closure.location.range,
                decl: :arg
              )
              region.closure.parameters.push locals.last
            end
            # @todo Optional args, keyword args, etc.
            if node.children[6]
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: node.children[6].to_s,
                presence: region.closure.location.range,
                decl: :restarg
              )
              region.closure.parameters.push locals.last
            end
            if node.children[8] && node.children[8].children.first
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: node.children[8].children.first.to_s,
                presence: region.closure.location.range,
                decl: :kwrestarg
              )
              region.closure.parameters.push locals.last
            end
            if node.children.last
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: node.children.last.to_s,
                presence: region.closure.location.range,
                decl: :blockarg
              )
              region.closure.parameters.push locals.last
            end
            process_children
          end
        end
      end
    end
  end
end
