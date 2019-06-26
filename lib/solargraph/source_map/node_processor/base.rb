# frozen_string_literal: true

module Solargraph
  class SourceMap
    module NodeProcessor
      class Base
        include Solargraph::Source::NodeMethods

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Region]
        attr_reader :region

        # @return [Array<Pin::Base>]
        attr_reader :pins

        # @return [Array<Pin::Base>]
        attr_reader :locals

        # @param node [Parser::AST::Node]
        # @param region [Region]
        # @param pins [Array<Pin::Base>]
        def initialize node, region, pins, locals
          @node = node
          @region = region
          @pins = pins
          @locals = locals
        end

        protected

        # Subclasses should override this method to generate new pins.
        #
        # @return [void]
        def process
          raise NoMethodError, "#{self.class} does not implement the `process` method"
        end

        private

        # @param subregion [Region]
        # @return [void]
        def process_children subregion = region
          node.children.each do |child|
            next unless child.is_a?(Parser::AST::Node)
            NodeProcessor.process(child, subregion, pins, locals)
          end
        end

        # @param node [Parser::AST::Node]
        # @return [Solargraph::Location]
        def get_node_location(node)
          st = Position.new(node.loc.line, node.loc.column)
          en = Position.new(node.loc.last_line, node.loc.last_column)
          range = Range.new(st, en)
          Location.new(region.filename, range)
        end

        def comments_for(node)
          region.source.comments_for(node)
        end

        def named_path_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.path && !pin.path.empty? && pin.location.range.contain?(position)}.last
        end

        # @todo Candidate for deprecation
        def block_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position)}.last
        end

        # @todo Candidate for deprecation
        def closure_pin position
          pins.select{|pin| pin.is_a?(Pin::Closure) && pin.location.range.contain?(position)}.last
        end

        private

        def method_args
          return [] if node.nil?
          list = nil
          args = []
          node.children.each { |c|
            if c.is_a?(AST::Node) and c.type == :args
              list = c
              break
            end
          }
          return args if list.nil?
          list.children.each { |c|
            if c.type == :arg
              args.push c.children[0].to_s
            elsif c.type == :restarg
              args.push "*#{c.children[0]}"
            elsif c.type == :optarg
              args.push "#{c.children[0]} = #{region.code_for(c.children[1])}"
            elsif c.type == :kwarg
              args.push "#{c.children[0]}:"
            elsif c.type == :kwoptarg
              args.push "#{c.children[0]}: #{region.code_for(c.children[1])}"
            elsif c.type == :kwrestarg
              args.push "**#{c.children[0]}"
            elsif c.type == :blockarg
              args.push "&#{c.children[0]}"
            end
          }
          args
        end
      end
    end
  end
end
