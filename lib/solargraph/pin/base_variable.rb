# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      # include Solargraph::Source::NodeMethods
      include Solargraph::Parser::NodeMethods

      # @return [Parser::AST::Node, nil]
      attr_reader :assignment

      attr_accessor :mass_assignment

      # @return [Range, nil]
      attr_reader :presence

      # @return [Boolean]
      attr_reader :presence_certain

      def presence_certain?
        @presence_certain
      end

      # @param presence [Range, nil]
      # @param presence_certain [Boolean]
      # @param return_type [ComplexType, nil]
      # @param exclude_return_type [ComplexType, nil] Ensure any return
      #   type returned will never include these unique types in the
      #   unique types of its complex type
      # @param assignment [Parser::AST::Node, nil]
      def initialize assignment: nil, presence: nil, presence_certain: false, return_type: nil, exclude_return_type: nil, **splat
        super(**splat)
        @assignment = assignment
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = nil
        @return_type = return_type
        @presence = presence
        @presence_certain = presence_certain
        @exclude_return_type = exclude_return_type
      end

      def reset_generated!
        @return_type_minus_exclusions = nil
        super
      end

      def combine_with(other, attrs={})
        attrs.merge({
          assignment: assert_same(other, :assignment),
          mass_assignment: assert_same(other, :mass_assignment),
          return_type: combine_return_type(other),
        })
        super(other, attrs)
      end

      def combine_with(other, attrs={})
        new_attrs = {
          assignment: assert_same(other, :assignment),
          presence_certain: assert_same(other, :presence_certain?),
          exclude_return_type: combine_types(other, :exclude_return_type),
        }.merge(attrs)
        new_attrs[:presence] = assert_same(other, :presence) unless attrs.key?(:presence)
        new_attrs[:presence_certain] = assert_same(other, :presence_certain) unless attrs.key?(:presence_certain)

        super(other, new_attrs)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def nil_assignment?
        # this will always be false - should it be return_type ==
        #   ComplexType::NIL or somesuch?
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
            # @sg-ignore Need to add nil check here
            clip = api_map.clip_at(location.filename, pos)
            # Use the return node for inference. The clip might infer from the
            # first node in a method call instead of the entire call.
            chain = Parser.chain(node, nil, nil)
            # @sg-ignore Need to add nil check here
            result = chain.infer(api_map, closure, clip.locals).self_to_type(closure.context)
            types.push result unless result.undefined?
          end
        end
        types
      end

      attr_reader :exclude_return_type

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        if presence_certain? && return_type&.defined?
          # flow sensitive typing has already figured out this type
          # @sg-ignore need to improve handling of &.
          return return_type.qualify(api_map, *gates)
        end

        unless @assignment.nil?
          # @sg-ignore sensitive typing needs to handle "unless foo.nil?"
          types = return_types_from_node(@assignment, api_map)
          exclude_items = exclude_return_type&.items&.uniq
          return ComplexType.new(types.flat_map(&:items).uniq - (exclude_items || [])) unless types.empty?
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

      # @param other [Object]
      def == other
        return false unless super
        assignment == other.assignment
      end

      def type_desc
        # @sg-ignore literal arrays in this module turn into ::Solargraph::Source::Chain::Array
        "#{super} = #{assignment&.type.inspect}"
      end

      # @return [ComplexType, nil]
      def return_type
        return_type_minus_exclusions(@return_type || generate_complex_type)
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        # @sg-ignore Need to add nil check here
        location.filename == other_loc.filename &&
          presence&.include?(other_loc.range.start) &&
          # @sg-ignore Need to add nil check here
          match_named_closure(other_closure, closure)
      end

      private

      attr_reader :exclude_return_type

      # @param needle [Pin::Base]
      # @param haystack [Pin::Base]
      # @return [Boolean]
      def match_named_closure needle, haystack
        return true if needle == haystack || haystack.is_a?(Pin::Block)
        cursor = haystack
        until cursor.nil?
          return true if needle.path == cursor.path
          return false if cursor.path && !cursor.path.empty?
          # @sg-ignore Need to add nil check here
          cursor = cursor.closure
        end
        false
      end

      # @param raw_return_type [ComplexType, nil]
      # @return [ComplexType, nil]
      def return_type_minus_exclusions(raw_return_type)
        @return_type_minus_exclusions ||=
          if exclude_return_type && raw_return_type
            types = raw_return_type.items - exclude_return_type.items
            types = [ComplexType::UniqueType::UNDEFINED] if types.empty?
            ComplexType.new(types)
          else
            raw_return_type
          end
        @return_type_minus_exclusions
      end

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [ComplexType, nil]
      def combine_types(other, attr)
        # @type [ComplexType, nil]
        type1 = send(attr)
        # @type [ComplexType, nil]
        type2 = other.send(attr)
        if type1 && type2
          types = (type1.items + type2.items).uniq
          ComplexType.new(types)
        else
          type1 || type2
        end
      end

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
