# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        # Maps the methods that class-level methods create with define_method,
        # e.g., +add_flash_types :alert+ defines +#alert+. See Template for
        # which methods qualify.
        module DefineMethodDefinitions
          autoload :Template,  'solargraph/parser/parser_gem/node_processors/define_method_definitions/template'
          autoload :CallSites, 'solargraph/parser/parser_gem/node_processors/define_method_definitions/call_sites'

          # Records a Template on a method's pin when its body calls
          # define_method or define_singleton_method. Each call is examined
          # once, with only its enclosing blocks, so mapping stays linear.
          class DefinerNode < Parser::NodeProcessor::Base
            # @return [Boolean] continue processing the next processor of the same node.
            def process
              return true unless Template::DEFINERS.key?(node.children[1])
              # @type [::Array<::Parser::AST::Node>]
              blocks = []
              closure = region.closure
              while closure.is_a?(Pin::Block)
                return true if blocks.length == Template::MAX_BLOCK_DEPTH
                blocks.unshift closure.node
                closure = closure.closure
              end
              return true unless closure.is_a?(Pin::Method)
              record closure.call_site_templates, Template.from_send(node, closure.node, blocks)
              true
            end

            private

            # @param templates [::Array<Object>]
            # @param template [Template, nil]
            # @return [void]
            def record templates, template
              return if template.nil?
              return if templates.any? { |t| t.is_a?(Template) && t.key == template.key }
              templates.push template
            end
          end
        end
      end
    end
  end
end
