# frozen_string_literal: true

module Solargraph
  module Pin
    class Parameter < LocalVariable
      # @return [Symbol]
      attr_reader :decl

      # @return [String]
      attr_reader :asgn_code

      # @param decl [::Symbol] :arg, :optarg, :kwarg, :kwoptarg, :restarg, :kwrestarg, :block, :blockarg
      # @param asgn_code [String, nil]
      # @param return_type [ComplexType, nil]
      def initialize decl: :arg, asgn_code: nil, return_type: nil, **splat
        super(**splat)
        @asgn_code = asgn_code
        @decl = decl
        @return_type = return_type
      end

      def keyword?
        [:kwarg, :kwoptarg].include?(decl)
      end

      def kwrestarg?
        decl == :kwrestarg || (assignment && [:HASH, :hash].include?(assignment.type))
      end

      def restarg?
        decl == :restarg
      end

      def rest?
        decl == :restarg || decl == :kwrestarg
      end

      def block?
        [:block, :blockarg].include?(decl)
      end

      def to_rbs
        case decl
        when :optarg
          "?#{super}"
        when :kwarg
          "#{name}: #{return_type.to_rbs}"
        when :kwoptarg
          "?#{name}: #{return_type.to_rbs}"
        when :restarg
          "*#{super}"
        when :kwrestarg
          "**#{super}"
        else
          super
        end
      end

      # @return [String]
      def full
        case decl
        when :optarg
          "#{name} = #{asgn_code || '?'}"
        when :kwarg
          "#{name}:"
        when :kwoptarg
          "#{name}: #{asgn_code || '?'}"
        when :restarg
          "*#{name}"
        when :kwrestarg
          "**#{name}"
        when :block, :blockarg
          "&#{name}"
        else
          name
        end
      end

      # @return [ComplexType]
      def return_type
        if @return_type.nil?
          @return_type = ComplexType::UNDEFINED
          found = param_tag
          @return_type = ComplexType.try_parse(*found.types) unless found.nil? or found.types.nil?
          if @return_type.undefined?
            if decl == :restarg
              @return_type = ComplexType.try_parse('::Array')
            elsif decl == :kwrestarg
              @return_type = ComplexType.try_parse('::Hash')
            elsif decl == :blockarg
              @return_type = ComplexType.try_parse('::Proc')
            end
          end
        end
        super
        @return_type
      end

      # The parameter's zero-based location in the block's signature.
      #
      # @return [Integer]
      def index
        # @type [Method, Block]
        method_pin = closure
        method_pin.parameter_names.index(name)
      end

      # @param api_map [ApiMap]
      def typify api_map
        return return_type.qualify(api_map, closure.context.namespace) unless return_type.undefined?
        closure.is_a?(Pin::Block) ? typify_block_param(api_map) : typify_method_param(api_map)
      end

      def documentation
        tag = param_tag
        return '' if tag.nil? || tag.text.nil?
        tag.text
      end

      def try_merge! pin
        return false unless super && closure == pin.closure
        true
      end

      private

      # @return [YARD::Tags::Tag, nil]
      def param_tag
        found = nil
        params = closure.docstring.tags(:param)
        params.each do |p|
          next unless p.name == name
          found = p
          break
        end
        if found.nil? and !index.nil?
          found = params[index] if params[index] && (params[index].name.nil? || params[index].name.empty?)
        end
        found
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify_block_param api_map
        if closure.is_a?(Pin::Block) && closure.receiver
          return closure.typify_parameters(api_map)[index]
        end
        ComplexType::UNDEFINED
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify_method_param api_map
        meths = api_map.get_method_stack(closure.full_context.tag, closure.name, scope: closure.scope)
        # meths.shift # Ignore the first one
        meths.each do |meth|
          found = nil
          params = meth.docstring.tags(:param) + see_reference(docstring, api_map)
          params.each do |p|
            next unless p.name == name
            found = p
            break
          end
          if found.nil? and !index.nil?
            found = params[index] if params[index] && (params[index].name.nil? || params[index].name.empty?)
          end
          return ComplexType.try_parse(*found.types).qualify(api_map, meth.context.namespace) unless found.nil? || found.types.nil?
        end
        ComplexType::UNDEFINED
      end

      # @param heredoc [YARD::Docstring]
      # @param api_map [ApiMap]
      # @param skip [::Array]
      # @return [::Array<YARD::Tags::Tag>]
      def see_reference heredoc, api_map, skip = []
        heredoc.ref_tags.each do |ref|
          next unless ref.tag_name == 'param' && ref.owner
          result = resolve_reference(ref.owner.to_s, api_map, skip)
          return result unless result.nil?
        end
        []
      end

      # @param ref [String]
      # @param api_map [ApiMap]
      # @param skip [::Array]
      # @return [::Array<YARD::Tags::Tag>, nil]
      def resolve_reference ref, api_map, skip
        return nil if skip.include?(ref)
        skip.push ref
        parts = ref.split(/[\.#]/)
        if parts.first.empty?
          path = "#{namespace}#{ref}"
        else
          fqns = api_map.qualify(parts.first, namespace)
          return nil if fqns.nil?
          path = fqns + ref[parts.first.length] + parts.last
        end
        pins = api_map.get_path_pins(path)
        pins.each do |pin|
          params = pin.docstring.tags(:param)
          return params unless params.empty?
        end
        pins.each do |pin|
          params = see_reference(pin.docstring, api_map, skip)
          return params unless params.empty?
        end
        nil
      end
    end
  end
end
