# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Parser::NodeMethods
      # include Solargraph::Source::NodeMethods

      # @return [Parser::AST::Node, nil]
      attr_reader :assignment

      attr_accessor :mass_assignment

      # @param assignment [Parser::AST::Node, nil]
      def initialize assignment: nil, **splat
        super(**splat)
        @assignment = assignment
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = nil
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type.nil?
      end

      def variable?
        true
      end

      # @param parent_node [Parser::AST::Node]
      # @param api_map [ApiMap]
      # @return [::Array<ComplexType>]
      def return_types_from_node(parent_node, api_map)
        types = []
        value_position_nodes_only(parent_node).each do |node|
          # Nil nodes may not have a location
          if node.nil? || node.type == :NIL || node.type == :nil
            types.push ComplexType::NIL
          else
            rng = Range.from_node(node)
            next if rng.nil?
            pos = rng.ending
            clip = api_map.clip_at(location.filename, pos)
            # Use the return node for inference. The clip might infer from the
            # first node in a method call instead of the entire call.
            chain = Parser.chain(node, nil, nil)
            result = chain.infer(api_map, closure, clip.locals).self_to_type(closure.context)
            types.push result unless result.undefined?
          end
        end
        logger.debug { "BaseVariable#return_types_from_node(#{parent_node}) => #{types.map(&:rooted_tags)}" }
        types
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        unless @assignment.nil?
          types = return_types_from_node(@assignment, api_map)
          return ComplexType.new(types.uniq) unless types.empty?
        end

        unless @mass_assignment.nil?
          mass_node, index = @mass_assignment
          types = return_types_from_node(mass_node, api_map)
          types.map! do |type|
            if type.tuple?
              type.all_params[index]
            elsif ['::Array', '::Set', '::Enumerable'].include?(type.rooted_name)
              type.all_params.first
            end
          end.compact!
          return ComplexType.new(types.uniq) unless types.empty?
        end

        ComplexType::UNDEFINED
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_type = pin.return_type
        true
      end

      def desc
        "#{to_rbs} = #{assignment&.type.inspect}"
      end

      include Logging

      private

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
