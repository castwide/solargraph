# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IvasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # s(:ivasgn, name, value) - value is absent when the target is in an mlhs
            node => [:ivasgn, Symbol => name, *rest]
            assignment = (rest in [::Parser::AST::Node => value, *]) ? value : nil

            loc = get_node_location(node)
            ivars.push Solargraph::Pin::InstanceVariable.new(
              location: loc,
              closure: region.closure,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1416
              name: name.to_s,
              comments: comments_for(node),
              type_assertion: type_assertion_for(node),
              assignment: assignment,
              source: :parser
            )
            if region.visibility == :module_function
              here = get_node_start_position(node)
              # @type [Pin::Closure, nil]
              named_path = named_path_pin(here)
              if named_path.is_a?(Pin::Method)
                ivars.push Solargraph::Pin::InstanceVariable.new(
                  location: loc,
                  closure: Pin::Namespace.new(type: :module, closure: region.closure.closure,
                                              name: region.closure.name),
                  # @sg-ignore https://github.com/castwide/solargraph/pull/1416
                  name: name.to_s,
                  comments: comments_for(node),
                  type_assertion: type_assertion_for(node),
                  assignment: assignment,
                  source: :parser
                )
              end
            end
            process_children
          end
        end
      end
    end
  end
end
