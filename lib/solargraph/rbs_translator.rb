# frozen_string_literal: true

module Solargraph
  # Convert RBS types to complex types and pins.
  #
  module RbsTranslator
    RBS_TO_YARD_TYPE = {
      'bool' => 'Boolean',
      'string' => 'String',
      'int' => 'Integer',
      'untyped' => '',
      'NilClass' => 'nil'
    }.freeze

    # Relative type names (e.g. `Bar` in an inline `#: () -> Bar`) stay
    # unrooted so they resolve against the pin's namespace like YARD tags
    # do. Absolute names (`::Bar`, or any name from an RBS environment
    # after `resolve_type_names`) and RBS builtins stay rooted.
    #
    # @param type [RBS::Types::t]
    # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
    # @return [ComplexType]
    def self.to_complex_type type, type_alias_decls: {}
      to_type(type, type_alias_decls)
    end

    # @param param_type [RBS::Types::Function::Param]
    # @param name [String]
    # @param decl [Symbol]
    # @param closure [Pin::Closure]
    # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
    # @return [Pin::Parameter]
    def self.to_parameter_pin param_type, name, decl, closure, type_alias_decls: {}
      return_type = if decl == :restarg
                      ComplexType.parse('Array')
                    elsif decl == :kwrestarg
                      ComplexType.parse('Hash{Symbol => Object}')
                    else
                      RbsTranslator.to_complex_type(param_type.type, type_alias_decls: type_alias_decls)
                    end
      Solargraph::Pin::Parameter.new(decl: decl, name: name, closure: closure, return_type: return_type, source: :rbs, type_location: to_sg_location(param_type.location) || closure.type_location)
    end

    # @param method_type [RBS::MethodType, RBS::Types::Block]
    # @param closure [Pin::Closure]
    # @param parameter_names [Array<String>]
    # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
    # @return [Array<Pin::Parameter>]
    def self.to_parameter_pins method_type, closure, parameter_names = [], type_alias_decls: {}
      if defined?(RBS::Types::UntypedFunction) && method_type.type.is_a?(RBS::Types::UntypedFunction)
        return [
          Solargraph::Pin::Parameter.new(decl: :restarg, name: 'arg', closure: closure, source: :rbs)
        ]
      end

      arg_num = 0
      params = []
      method_type.type.required_positionals.each do |param|
        # @sg-ignore Unresolved call to name on RBS::Types::Function::Param
        params.push RbsTranslator.to_parameter_pin(param, param.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :arg, closure, type_alias_decls: type_alias_decls)
        arg_num += 1
      end
      method_type.type.optional_positionals.each do |param|
        # @sg-ignore Unresolved call to name on RBS::Types::Function::Param
        params.push RbsTranslator.to_parameter_pin(param, param.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :optarg, closure, type_alias_decls: type_alias_decls)
        arg_num += 1
      end
      if method_type.type.rest_positionals
        rest_positionals = method_type.type.rest_positionals
        # @sg-ignore Unresolved call to name on RBS::Types::Function::Param
        rest_name = rest_positionals.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}"
        params.push RbsTranslator.to_parameter_pin(rest_positionals, rest_name, :restarg, closure, type_alias_decls: type_alias_decls)
        arg_num += 1
      end
      method_type.type.required_keywords.each do |param|
        # @sg-ignore Unresolved calls to last, first on generic<D>
        params.push RbsTranslator.to_parameter_pin(param.last, param.first.to_s, :kwarg, closure, type_alias_decls: type_alias_decls)
        arg_num += 1
      end
      method_type.type.optional_keywords.each do |param|
        # @sg-ignore Unresolved calls to last, first on generic<D>
        params.push RbsTranslator.to_parameter_pin(param.last, param.first.to_s, :kwoptarg, closure, type_alias_decls: type_alias_decls)
        arg_num += 1
      end
      if method_type.type.rest_keywords
        rest_keywords = method_type.type.rest_keywords
        # @sg-ignore Unresolved call to name on RBS::Types::Function::Param
        rest_keywords_name = rest_keywords.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}"
        params.push RbsTranslator.to_parameter_pin(rest_keywords, rest_keywords_name, :kwrestarg, closure, type_alias_decls: type_alias_decls)
      end
      params
    end

    # @param method_type [RBS::MethodType]
    # @param closure [Pin::Closure]
    # @param parameter_names [Array<String>]
    # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
    # @return [Pin::Signature]
    def self.to_signature method_type, closure, parameter_names = [], type_alias_decls: {}
      # There may be edge cases here around different signatures
      # having different type params / orders - we may need to match
      # this data model and have generics live in signatures to
      # handle those correctly
      generics = method_type.type_params.map(&:name).map(&:to_s).uniq
      parameters = to_parameter_pins(method_type, closure, parameter_names, type_alias_decls: type_alias_decls)
      return_type = to_complex_type(method_type.type.return_type, type_alias_decls: type_alias_decls)
      block = if method_type.block
                # @sg-ignore https://github.com/castwide/solargraph/issues/1249
                block_parameters = to_parameter_pins(method_type.block, closure, type_alias_decls: type_alias_decls)
                block_return_type = to_complex_type(method_type.block.type.return_type, type_alias_decls: type_alias_decls)
                Pin::Signature.new(generics: generics, parameters: block_parameters, return_type: block_return_type, source: :rbs, type_location: closure.location, closure: closure)
              end
      Pin::Signature.new(generics: generics, parameters: parameters, return_type: return_type, block: block,
                         block_required: method_type.block&.required || false, source: :rbs, type_location: closure.location, closure: closure)
    end

    # @param location [RBS::Location, nil]
    # @return [Solargraph::Location, nil]
    def self.to_sg_location location
      return nil if location&.name.nil?

      start_pos = Position.new(location.start_line - 1, location.start_column)
      end_pos = Position.new(location.end_line - 1, location.end_column)
      range = Range.new(start_pos, end_pos)
      Location.new(location.name.to_s, range)
    end

    class << self
      private

      # @param type [RBS::Types::t]
      # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
      # @param expanding_aliases [Array<String>] Names of aliases already
      #   being expanded in this call chain, to detect recursive aliases
      # @return [ComplexType]
      def to_type type, type_alias_decls = {}, expanding_aliases = []
        case type
        when RBS::Types::Optional
          # @sg-ignore flow sensitive typing should support case/when
          ComplexType.new([to_type(type.type, type_alias_decls, expanding_aliases), ComplexType::NIL])
        when RBS::Types::Bases::Bool
          ComplexType::BOOLEAN
        when RBS::Types::Tuple
          # @sg-ignore flow sensitive typing should support case/when
          members = type.types.map { |member| to_type(member, type_alias_decls, expanding_aliases) }
          named_type('Array', members, parameters_type: :fixed)
        when RBS::Types::Literal
          # @sg-ignore flow sensitive typing should support case/when
          named_type(type.literal.inspect)
        when RBS::Types::Union, RBS::Types::Intersection
          # An intersection reads as the union of its members until
          # Solargraph has an intersection type.
          # @sg-ignore flow sensitive typing should support case/when
          ComplexType.new(type.types.map { |member| to_type(member, type_alias_decls, expanding_aliases) })
        when RBS::Types::Record
          # @todo Better record support
          named_type('Hash')
        when RBS::Types::Bases::Nil
          ComplexType::NIL
        when RBS::Types::Bases::Void
          ComplexType::VOID
        when RBS::Types::Variable
          # @sg-ignore flow sensitive typing should support case/when
          parameter = ComplexType::UniqueType.new(type.name.to_s, rooted: false)
          named_type(ComplexType::GENERIC_TAG_NAME, [parameter])
        when RBS::Types::Bases::Self, RBS::Types::Bases::Instance
          ComplexType::SELF
        when RBS::Types::Bases::Top
          # `Top` is the most super superclass
          named_type('BasicObject')
        when RBS::Types::Proc
          named_type('Proc')
        when RBS::Types::Alias
          # Expand so conformance checks see the members, not the name. A
          # generic alias falls back: args are not substituted, so expanding
          # would leak an unbound generic<T>.
          # @sg-ignore flow sensitive typing should support case/when
          alias_name = type.name.to_s
          alias_decl = type_alias_decls[alias_name]
          # @sg-ignore flow sensitive typing should support case/when
          if alias_decl.nil? || expanding_aliases.include?(alias_name) || !type.args.empty?
            # @sg-ignore flow sensitive typing should support case/when
            ComplexType.new([build_type(type.name, type.args, type_alias_decls, expanding_aliases)])
          else
            # The alias body belongs to the alias's declaration, not the
            # use site, so its names stay rooted even when a core-less
            # environment left them relative.
            to_type(alias_decl.type, type_alias_decls, expanding_aliases + [alias_name]).force_rooted
          end
        when RBS::Types::ClassInstance, RBS::Types::Interface
          # `Interface` represents a mix-in module which can be considered a
          # subtype of a consumer of it
          # @sg-ignore flow sensitive typing should support case/when
          ComplexType.new([build_type(type.name, type.args, type_alias_decls, expanding_aliases)])
        when RBS::Types::ClassSingleton
          # e.g., singleton(String)
          # @sg-ignore flow sensitive typing should support case/when
          ComplexType.new([build_type(type.name, [], type_alias_decls, expanding_aliases)])
        when RBS::Types::Bases::Any, RBS::Types::Bases::Bottom
          # `Bottom`` is used in contexts where nothing will ever return
          # - e.g., it could be the return type of 'exit()' or 'raise'
          # @todo define a specific bottom type and use it to
          #   determine dead code
          #
          ComplexType::UNDEFINED
        else
          Solargraph.logger.warn "Unrecognized RBS type: #{type.class} at #{type.location}"
          ComplexType::UNDEFINED
        end
      end

      # @param name [String]
      # @param subtypes [Array<ComplexType, ComplexType::UniqueType>]
      # @param parameters_type [Symbol]
      # @return [ComplexType]
      def named_type name, subtypes = [], parameters_type: :list
        parameters_type = nil if subtypes.empty?
        ComplexType.new([ComplexType::UniqueType.new(name, [], subtypes, rooted: true, parameters_type: parameters_type)])
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
      # @param expanding_aliases [Array<String>]
      # @return [ComplexType::UniqueType]
      def build_type type_name, type_args = [], type_alias_decls = {}, expanding_aliases = []
        yard_base = RBS_TO_YARD_TYPE[type_name.relative!.to_s]
        base = yard_base || type_name.relative!.to_s
        rooted = !yard_base.nil? || type_name.absolute?
        params = type_args.map { |a| to_type(a, type_alias_decls, expanding_aliases) }
        if base == 'Hash' && params.length == 2 && params.any?(&:defined?)
          ComplexType::UniqueType.new(base, [params.first], [params.last], rooted: rooted, parameters_type: :hash)
        else
          ComplexType::UniqueType.new(base, [], params.reject(&:undefined?), rooted: rooted, parameters_type: :list)
        end
      end
    end
  end
end
