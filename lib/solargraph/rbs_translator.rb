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

    # @param type [RBS::Types::t]
    # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
    # @return [ComplexType]
    def self.to_complex_type type, type_alias_decls: {}
      tag = type_to_tag(type, type_alias_decls)
      ComplexType.try_parse(tag).force_rooted
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
                # @sg-ignore The `if method_type.block` guard above doesn't narrow nil out of this
                #   second `method_type.block` call: https://github.com/castwide/solargraph/issues/1249
                block_parameters = to_parameter_pins(method_type.block, closure, type_alias_decls: type_alias_decls)
                block_return_type = to_complex_type(method_type.block.type.return_type, type_alias_decls: type_alias_decls)
                Pin::Signature.new(generics: generics, parameters: block_parameters, return_type: block_return_type, source: :rbs, type_location: closure.location, closure: closure)
              end
      Pin::Signature.new(generics: generics, parameters: parameters, return_type: return_type, block: block, source: :rbs, type_location: closure.location, closure: closure)
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
      # @return [String]
      def type_to_tag type, type_alias_decls = {}, expanding_aliases = []
        case type
        when RBS::Types::Optional
          # @sg-ignore flow sensitive typing should support case/when
          "#{type_to_tag(type.type, type_alias_decls, expanding_aliases)}, nil"
        when RBS::Types::Bases::Bool
          'Boolean'
        when RBS::Types::Tuple
          # @sg-ignore flow sensitive typing should support case/when
          "Array(#{type.types.map { |t| type_to_tag(t, type_alias_decls, expanding_aliases) }.join(', ')})"
        when RBS::Types::Literal
          # @sg-ignore flow sensitive typing should support case/when
          type.literal.inspect
        when RBS::Types::Union
          # @sg-ignore flow sensitive typing should support case/when
          type.types.map { |t| type_to_tag(t, type_alias_decls, expanding_aliases) }.join(', ')
        when RBS::Types::Record
          # @todo Better record support
          'Hash'
        when RBS::Types::Bases::Nil
          'nil'
        when RBS::Types::Bases::Void
          'void'
        when RBS::Types::Variable
          # @sg-ignore flow sensitive typing should support case/when
          "#{Solargraph::ComplexType::GENERIC_TAG_NAME}<#{type.name}>"
        when RBS::Types::Bases::Self, RBS::Types::Bases::Instance
          'self'
        when RBS::Types::Bases::Top
          # `Top` is the most super superclass
          'BasicObject'
        when RBS::Types::Intersection
          # @sg-ignore flow sensitive typing should support case/when
          type.types.map { |member| type_to_tag(member, type_alias_decls, expanding_aliases) }.join(', ')
        when RBS::Types::Proc
          'Proc'
        when RBS::Types::Alias
          # A top-level type alias use, e.g., 'bool' in "type bool = true | false".
          #
          # Expand to the alias's underlying type so structural
          # conformance checks (e.g., typechecking) can compare against
          # its actual members rather than its nominal name. Fall back to
          # the nominal tag if the alias definition isn't known, if it's
          # recursive, or if it's generic (e.g. "type box[T] = Array[T] |
          # nil") — expanding those would leak an unbound `generic<T>`
          # tag, since args aren't substituted into the expansion.
          # @sg-ignore flow sensitive typing should support case/when
          alias_name = type.name.to_s
          alias_decl = type_alias_decls[alias_name]
          # @sg-ignore flow sensitive typing should support case/when
          if alias_decl.nil? || expanding_aliases.include?(alias_name) || !type.args.empty?
            # @sg-ignore flow sensitive typing should support case/when
            type_tag(type.name, type.args, type_alias_decls, expanding_aliases)
          else
            type_to_tag(alias_decl.type, type_alias_decls, expanding_aliases + [alias_name])
          end
        when RBS::Types::ClassInstance, RBS::Types::Interface
          # `Interface` represents a mix-in module which can be considered a
          # subtype of a consumer of it
          # @sg-ignore flow sensitive typing should support case/when
          type_tag(type.name, type.args, type_alias_decls, expanding_aliases)
        when RBS::Types::ClassSingleton
          # e.g., singleton(String)
          # @sg-ignore flow sensitive typing should support case/when
          type_tag(type.name, [], type_alias_decls, expanding_aliases)
        when RBS::Types::Bases::Any, RBS::Types::Bases::Bottom
          # `Bottom`` is used in contexts where nothing will ever return
          # - e.g., it could be the return type of 'exit()' or 'raise'
          # @todo define a specific bottom type and use it to
          #   determine dead code
          #
          'undefined'
        else
          Solargraph.logger.warn "Unrecognized RBS type: #{type.class} at #{type.location}"
          'undefined'
        end
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
      # @param expanding_aliases [Array<String>]
      # @return [String]
      def type_tag type_name, type_args = [], type_alias_decls = {}, expanding_aliases = []
        build_type(type_name, type_args, type_alias_decls, expanding_aliases).tags
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @param type_alias_decls [Hash{String => RBS::AST::Declarations::TypeAlias}]
      # @param expanding_aliases [Array<String>]
      # @return [ComplexType::UniqueType]
      def build_type type_name, type_args = [], type_alias_decls = {}, expanding_aliases = []
        base = RBS_TO_YARD_TYPE[type_name.relative!.to_s] || type_name.relative!.to_s
        params = type_args.map { |a| type_to_tag(a, type_alias_decls, expanding_aliases) }.map do |t|
          ComplexType.try_parse(t)
        end
        if base == 'Hash' && params.length == 2
          ComplexType::UniqueType.new(base, [params.first], [params.last], rooted: true, parameters_type: :hash)
        else
          ComplexType::UniqueType.new(base, [], params.reject(&:undefined?), rooted: true, parameters_type: :list)
        end
      end
    end
  end
end
