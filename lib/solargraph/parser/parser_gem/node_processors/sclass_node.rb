# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SclassNode < Parser::NodeProcessor::Base
          # @sg-ignore @override is adding, not overriding
          def process
            # s(:sclass, target, body) - target is s(:self), s(:casgn, ...) or s(:const, ...)
            return unless node in [:sclass, ::Parser::AST::Node => sclass, *]

            # @todo Changing Parser::AST::Node to AST::Node below will
            #   cause type errors at strong level because the combined
            #   pin for AST::Node#children has return type
            #   "Array<AST::Node>, Array".  YARD annotations in AST
            #   provided the Array, RBS for Array<AST::Node>.  We
            #   should probably have a rule to combine "A, A<T>""
            #   types to "A<T>" if the "A" comes from YARD, with the
            #   rationale that folks tend to be less formal with types in
            #   YARD.
            case sclass
            in ::Parser::AST::Node[:self, *]
              closure = region.closure
            in ::Parser::AST::Node[:casgn, ::Parser::AST::Node | nil => scope, Symbol => const_name, *]

              names = [region.closure.namespace, region.closure.name]
              if scope.nil? && names.last != const_name.to_s
                names << const_name.to_s
              else
                names.push NodeMethods.unpack_name(scope), const_name.to_s
              end
              name = names.reject(&:empty?).join('::')
              closure = Solargraph::Pin::Namespace.new(name: name, location: region.closure.location, source: :parser)
            in ::Parser::AST::Node[:const, *]
              names = [region.closure.namespace, region.closure.name]
              also = NodeMethods.unpack_name(sclass)
              names << also if also != region.closure.name
              name = names.reject(&:empty?).join('::')
              closure = Solargraph::Pin::Namespace.new(name: name, location: region.closure.location, source: :parser)
            else
              return
            end
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
