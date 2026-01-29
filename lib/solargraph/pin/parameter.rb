# frozen_string_literal: true

module Solargraph
  module Pin
    class Parameter < LocalVariable
      # @return [::Symbol]
      attr_reader :decl

      # @return [String]
      attr_reader :asgn_code

      # allow this to be set to the method after the method itself has
      # been created
      attr_writer :closure

      # @param decl [::Symbol] :arg, :optarg, :kwarg, :kwoptarg, :restarg, :kwrestarg, :block, :blockarg
      # @param asgn_code [String, nil]
      def initialize decl: :arg, asgn_code: nil, **splat
        super(**splat)
        @asgn_code = asgn_code
        @decl = decl
      end

      def type_location
        super || closure&.type_location
      end

      def location
        super || closure&.type_location
      end

      def combine_with(other, attrs={})
        # Parameters can be combined with local variables
        new_attrs = if other.is_a?(Parameter)
                      {
                        decl: assert_same(other, :decl),
                        asgn_code: choose(other, :asgn_code)
                      }
                    else
                      {
                        decl: decl,
                        asgn_code: asgn_code
                      }
                    end
        super(other, new_attrs.merge(attrs))
      end

      def combine_return_type(other)
        out = super
        if out&.undefined?
          # allow our return_type method to provide a better type
          # using :param tag
          out = nil
        end
        out
      end

      def keyword?
        [:kwarg, :kwoptarg].include?(decl)
      end

      def kwrestarg?
        # @sg-ignore flow sensitive typing needs to handle attrs
        decl == :kwrestarg || (assignment && [:HASH, :hash].include?(assignment.type))
      end

      def needs_consistent_name?
        keyword?
      end

      # @return [String]
      def arity_decl
        name = (self.name || '(anon)')
        type = (return_type&.to_rbs || 'untyped')
        case decl
        when :arg
          ""
        when :optarg
          "?"
        when :kwarg
          "#{name}:"
        when :kwoptarg
          "?#{name}:"
        when :restarg
          "*"
        when :kwrestarg
          "**"
        else
          "(unknown decl: #{decl})"
        end
      end

      # @return [String]
      def type_arity_decl
        arity_decl + return_type.items.count.to_s
      end

      def arg?
        decl == :arg
      end

      def restarg?
        decl == :restarg
      end

      def mandatory_positional?
        decl == :arg
      end

      def positional?
        !keyword?
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

      # @return [String] the full name of the parameter, including any
      #   declarative symbols such as `*` or `:` indicating type of
      #   parameter. This is used in method signatures.
      def full_name
        case decl
        when :kwarg, :kwoptarg
          "#{name}:"
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

      def reset_generated!
        @return_type = nil if param_tag
        super
      end

      # @return [String]
      def full
        full_name + case decl
                    when :optarg
                      " = #{asgn_code || '?'}"
                    when :kwoptarg
                      " #{asgn_code || '?'}"
                    else
                      ''
                    end
      end

      # @sg-ignore super always sets @return_type to something
      # @return [ComplexType]
      def return_type
        if @return_type.nil?
          @return_type = ComplexType::UNDEFINED
          found = param_tag
          @return_type = ComplexType.try_parse(*found.types) unless found.nil? or found.types.nil?
          # @sg-ignore flow sensitive typing should be able to handle redefinition
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
      end

      # The parameter's zero-based location in the block's signature.
      #
      # @sg-ignore Need to add nil check here
      # @return [Integer]
      def index
        method_pin = closure
        # @sg-ignore Need to add nil check here
        method_pin.parameter_names.index(name)
      end

      # @param api_map [ApiMap]
      def typify api_map
        new_type = super
        return new_type if new_type.defined?

        # sniff based on param tags
        new_type = closure.is_a?(Pin::Block) ? typify_block_param(api_map) : typify_method_param(api_map)

        return adjust_type api_map, new_type.self_to_type(full_context) if new_type.defined?

        adjust_type api_map, super.self_to_type(full_context)
      end

      # @param atype [ComplexType]
      # @param api_map [ApiMap]
      def compatible_arg?(atype, api_map)
        # make sure we get types from up the method
        # inheritance chain if we don't have them on this pin
        ptype = typify api_map
        return true if ptype.undefined?

        return true if atype.conforms_to?(api_map,
                                          ptype,
                                          :method_call,
                                          [:allow_empty_params, :allow_undefined])
        ptype.generic?
      end

      # @sg-ignore flow sensitive typing needs to handle attrs
      def documentation
        tag = param_tag
        return '' if tag.nil? || tag.text.nil?
        tag.text
      end

      private

      def generate_complex_type
        nil
      end

      # @return [YARD::Tags::Tag, nil]
      def param_tag
        # @sg-ignore Need to add nil check here
        params = closure.docstring.tags(:param)
        # @sg-ignore Need to add nil check here
        params.each do |p|
          return p if p.name == name
        end
        # @sg-ignore Need to add nil check here
        params[index] if index && params[index] && (params[index].name.nil? || params[index].name.empty?)
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify_block_param api_map
        block_pin = closure
        if block_pin.is_a?(Pin::Block) && block_pin.receiver && index
          return block_pin.typify_parameters(api_map)[index]
        end
        ComplexType::UNDEFINED
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify_method_param api_map
        # @sg-ignore Need to add nil check here
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
          # @sg-ignore Need to add nil check here
          return ComplexType.try_parse(*found.types).qualify(api_map, *meth.closure.gates) unless found.nil? || found.types.nil?
        end
        ComplexType::UNDEFINED
      end

      # @param heredoc [YARD::Docstring]
      # @param api_map [ApiMap]
      # @param skip [::Array]
      #
      # @return [::Array<YARD::Tags::Tag>]
      def see_reference heredoc, api_map, skip = []
        # This should actually be an intersection type
        # @param ref [YARD::Tags::Tag, Solargraph::Yard::Tags::RefTag]
        heredoc.ref_tags.each do |ref|
          # @sg-ignore ref should actually be an intersection type
          next unless ref.tag_name == 'param' && ref.owner
          # @todo ref should actually be an intersection type
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
        parts = ref.split(/[.#]/)
        if parts.first.empty?
          path = "#{namespace}#{ref}"
        else
          fqns = api_map.qualify(parts.first, namespace)
          return nil if fqns.nil?
          # @sg-ignore Need to add nil check here
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
