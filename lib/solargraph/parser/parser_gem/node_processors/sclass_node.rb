# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SclassNode < Parser::NodeProcessor::Base
          # @sg-ignore @override is adding, not overriding
          def process
            sclass = node.children[0]
            # @todo Changing Parser::AST::Node to AST::Node below will
            #   cause type errors at strong level because the combined
            #   pin for AST::Node#children has return type
            #   "Array<AST::Node>, Array".  YARD annotations in AST
            #   provided the Array, RBS for Array<AST::Node>.  We
            #   should probably have a rule to combine "A, A<T>""
            #   types to "A<T>" if the "A" comes from YARD, with the
            #   rationale that folks tend to be less formal with types in
            #   YARD.
            # @sg-ignore https://github.com/castwide/solargraph/issues/1251
            if sclass.is_a?(::Parser::AST::Node) && sclass.type == :self
              closure = region.closure
            # @sg-ignore https://github.com/castwide/solargraph/issues/1251
            elsif sclass.is_a?(::Parser::AST::Node) && sclass.type == :casgn
              names = [region.closure.namespace, region.closure.name]
              # @sg-ignore https://github.com/castwide/solargraph/issues/1251
              if sclass.children[0].nil? && names.last != sclass.children[1].to_s
                # @sg-ignore https://github.com/castwide/solargraph/issues/1251
                names << sclass.children[1].to_s
              else
                # @sg-ignore https://github.com/castwide/solargraph/issues/1251
                names.push NodeMethods.unpack_name(sclass.children[0]), sclass.children[1].to_s
              end
              name = names.reject(&:empty?).join('::')
              closure = Solargraph::Pin::Namespace.new(name: name, location: region.closure.location, source: :parser)
            # @sg-ignore https://github.com/castwide/solargraph/issues/1251
            elsif sclass.is_a?(::Parser::AST::Node) && sclass.type == :const
              names = [region.closure.namespace, region.closure.name]
              # @sg-ignore https://github.com/castwide/solargraph/issues/1251
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
