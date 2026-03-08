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
    }

    # @param type [RBS::Types::Bases::Base]
    # @return [ComplexType]
    def self.to_complex_type(type)
      tag = type_to_tag(type)
      ComplexType.try_parse(tag).force_rooted
    end

    # @param param_type [RBS::Types::Function::Param]
    # @param name [String]
    # @param decl [Symbol]
    # @param closure [Pin::Closure]
    # @return [Pin::Signature]
    def self.to_parameter_pin(param_type, name, decl, closure)
      return_type = if decl == :restarg
        ComplexType.parse('Array')
      elsif decl == :kwrestarg
        ComplexType.parse('Hash{Symbol => Object}')
      else
        RbsTranslator.to_complex_type(param_type.type).force_rooted
      end
      Solargraph::Pin::Parameter.new(decl: decl, name: name, closure: closure, return_type: return_type, source: :rbs, type_location: to_sg_location(param_type.location) || closure.type_location)
    end

    # @param method_type [RBS::MethodType]
    # @param closure [Pin::Closure]
    # @param parameter_names [Array<String>]
    # @return [Array<Pin::Parameter>]
    def self.to_parameter_pins method_type, closure, parameter_names = []
      if defined?(RBS::Types::UntypedFunction) && method_type.type.is_a?(RBS::Types::UntypedFunction)
        return [
          Solargraph::Pin::Parameter.new(decl: :restarg, name: 'arg', closure: closure, source: :rbs)
        ]
      end

      arg_num = 0
      params = []
      method_type.type.required_positionals.each do |param|
        params.push RbsTranslator.to_parameter_pin(param, param.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :arg, closure)
        arg_num += 1
      end
      method_type.type.optional_positionals.each do |param|
        params.push RbsTranslator.to_parameter_pin(param, param.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :optarg, closure)
        arg_num += 1
      end
      if method_type.type.rest_positionals
        params.push RbsTranslator.to_parameter_pin(method_type.type.rest_positionals, method_type.type.rest_positionals.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :restarg, closure)
        arg_num += 1
      end
      method_type.type.required_keywords.each do |param|
        params.push RbsTranslator.to_parameter_pin(param.last, param.first.to_s, :kwarg, closure)
        arg_num += 1
      end
      method_type.type.optional_keywords.each do |param|
        params.push RbsTranslator.to_parameter_pin(param.last, param.first.to_s, :kwoptarg, closure)
        arg_num += 1
      end
      if method_type.type.rest_keywords
        params.push RbsTranslator.to_parameter_pin(method_type.type.rest_keywords, method_type.type.rest_keywords.name&.to_s || parameter_names[arg_num] || "arg_#{arg_num}", :kwrestarg, closure)
      end
      params
    end

    # @param method_type [RBS::MethodType]
    # @param closure [Pin::Closure]
    # @param parameter_names [Array<String>]
    # @return [Pin::Signature]
    def self.to_signature method_type, closure, parameter_names = []
      # There may be edge cases here around different signatures
      # having different type params / orders - we may need to match
      # this data model and have generics live in signatures to
      # handle those correctly
      generics = method_type.type_params.map(&:name).map(&:to_s).uniq
      parameters = to_parameter_pins(method_type, closure, parameter_names)
      return_type = to_complex_type(method_type.type.return_type)
      block = if method_type.block
        block_parameters = to_parameter_pins(method_type.block, closure)
        block_return_type = to_complex_type(method_type.block.type.return_type)
        Pin::Signature.new(generics: generics, parameters: block_parameters, return_type: block_return_type, source: :rbs, type_location: closure.location, closure: closure)
      end
      Pin::Signature.new(generics: generics, parameters: parameters, return_type: return_type, block: block, source: :rbs, type_location: closure.location, closure: closure)
    end

    # @param type_name [RBS::TypeName]
    # @param type_args [Enumerable<RBS::Types::Bases::Base>]
    # @return [ComplexType::UniqueType]
    def self.build_unique_type(type_name, type_args = [])
      base = RBS_TO_YARD_TYPE[type_name.relative!.to_s] || type_name.relative!.to_s
      params = type_args.map do |a|
        RbsTranslator.to_complex_type(a).force_rooted
      end
      if base == 'Hash' && params.length == 2
        ComplexType::UniqueType.new(base, [params.first], [params.last], rooted: true, parameters_type: :hash)
      else
        ComplexType::UniqueType.new(base, [], params.reject(&:undefined?), rooted: true, parameters_type: :list)
      end
    end

    # @param location [RBS::Location, nil]
    # @return [Solargraph::Location, nil]
    def self.to_sg_location(location)
      return nil if location&.name.nil?

      start_pos = Position.new(location.start_line - 1, location.start_column)
      end_pos = Position.new(location.end_line - 1, location.end_column)
      range = Range.new(start_pos, end_pos)
      Location.new(location.name.to_s, range)
    end

    class << self
      private

      # @param type [RBS::Types::Bases::Base]
      # @return [String]
      def type_to_tag type
        case type
        when RBS::Types::Optional
          "#{type_to_tag(type.type)}, nil"
        when RBS::Types::Bases::Bool
          'Boolean'
        when RBS::Types::Tuple
          "Array(#{type.types.map { |t| type_to_tag(t) }.join(', ')})"
        when RBS::Types::Literal
          type.literal.inspect
        when RBS::Types::Union
          type.types.map { |t| type_to_tag(t) }.join(', ')
        when RBS::Types::Record
          # @todo Better record support
          'Hash'
        when RBS::Types::Bases::Nil
          'nil'
        when RBS::Types::Bases::Void
          'void'
        when RBS::Types::Variable
          "#{Solargraph::ComplexType::GENERIC_TAG_NAME}<#{type.name}>"
        when RBS::Types::Bases::Self, RBS::Types::Bases::Instance
          'self'
        when RBS::Types::Bases::Top
          # `Top` is the most super superclass
          'BasicObject'
        when RBS::Types::Intersection
          type.types.map { |member| type_to_tag(member) }.join(', ')
        when RBS::Types::Proc
          'Proc'
        when RBS::Types::ClassInstance, RBS::Types::Alias, RBS::Types::Interface
          # `Alias` is a top-level type alias, e.g., 'bool' in "type bool = true | false"
          # @todo ensure these get resolved after processing all aliases
          # @todo handle recursive aliases
          #
          # `Interface represents a mix-in module which can be considered a
          # subtype of a consumer of it
          #
          type_tag(type.name, type.args)
        when RBS::Types::ClassSingleton
          # e.g., singleton(String)
          type_tag(type.name)
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
      # @return [String]
      def type_tag(type_name, type_args = [])
        build_type(type_name, type_args).tags
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @return [ComplexType::UniqueType]
      def build_type(type_name, type_args = [])
        base = RBS_TO_YARD_TYPE[type_name.relative!.to_s] || type_name.relative!.to_s
        params = type_args.map { |a| type_to_tag(a) }.map do |t|
          ComplexType.try_parse(t).force_rooted
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
