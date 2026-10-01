# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SclassNode < Parser::NodeProcessor::Base
          on_node_pattern_enter '(sclass self _)', :process_self
          on_node_pattern_enter '(sclass (casgn $_ $_ ...) _)', :process_casgn
          on_node_pattern_enter '(sclass $const _)', :process_const
          on_node_pattern_enter '(sclass [!self !casgn !const] _)', :skip_children

          private

          # @return [void]
          def process_self
            process_singleton region.closure
          end

          # @param scope [::Parser::AST::Node, nil]
          # @param const_name [Symbol]
          # @return [void]
          def process_casgn scope, const_name
            names = [region.closure.namespace, region.closure.name]
            if scope.nil? && names.last != const_name.to_s
              names << const_name.to_s
            else
              # @sg-ignore Need to add nil check here
              names.push NodeMethods.unpack_name(scope), const_name.to_s
            end
            process_namespace names
          end

          # @param const [::Parser::AST::Node]
          # @return [void]
          def process_const const
            names = [region.closure.namespace, region.closure.name]
            also = NodeMethods.unpack_name(const)
            names << also if also != region.closure.name
            process_namespace names
          end

          # @param names [Array<String>]
          # @return [void]
          def process_namespace names
            name = names.reject(&:empty?).join('::')
            process_singleton Solargraph::Pin::Namespace.new(name: name, location: region.closure.location,
                                                             source: :parser)
          end

          # @param closure [Pin::Closure]
          # @return [void]
          def process_singleton closure
            pins.push Solargraph::Pin::Singleton.new(
              location: get_node_location(node),
              closure: closure,
              source: :parser
            )
            process_children region.update(visibility: :public, scope: :class, closure: pins.last)
          end
        end
      end
    end
  end
end
