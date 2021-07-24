require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    class Context
      attr_reader :visibility

      def initialize visibility = :public
        @visibility = visibility
      end
    end

    attr_reader :libraries

    attr_reader :pins

    def initialize libraries = []
      @loader = RBS::EnvironmentLoader.new
      @libraries = libraries.to_set
      libraries.each { |r| add_library(r) }
      # @type [RBS::Environment]
      @environment = RBS::Environment.from_loader(@loader).resolve_type_names
      pins.push Solargraph::Pin::ROOT_PIN
      @environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
    end

    def pins
      @pins ||= []
    end

    def unresolved_libraries
      @unresolved_libraries ||= []
    end

    private

    attr_reader :environment

    def add_library name
      if @loader.has_library?(library: name, version: nil)
        @loader.add library: name
      else
        unresolved_libraries.push name
        Solargraph.logger.warn "RBS mapper rejected unknown library #{name}"
      end
    end

    def builder
      @builder ||= RBS::DefinitionBuilder.new(env: environment)
    end

    def convert_decl_to_pin decl, closure
      case decl
      when RBS::AST::Declarations::Class
        class_decl_to_pin decl
      when RBS::AST::Declarations::Interface
        STDERR.puts "Skipping interface #{decl.name.relative!}"
      when RBS::AST::Declarations::Alias
        STDERR.puts "Skipping alias #{decl.name.relative!}"
      when RBS::AST::Declarations::Module
        module_decl_to_pin decl
      when RBS::AST::Declarations::Constant
        constant_decl_to_pin decl
      end
    end

    def convert_members_to_pin decl, closure
      context = Context.new
      decl.members.each { |m| context = convert_member_to_pin(m, closure, context) }
    end

    def convert_member_to_pin member, closure, context
      case member
      when RBS::AST::Members::MethodDefinition
        method_def_to_pin(member, closure)
      when RBS::AST::Members::Include
        include_to_pin(member, closure)
      when RBS::AST::Members::Alias
        alias_to_pin(member, closure)
      when RBS::AST::Members::Public
        return Context.new(visibility: :public)
      when RBS::AST::Members::Private
        return Context.new(visibility: :private)
      when RBS::AST::Declarations::Base
        convert_decl_to_pin(member, closure)
      else
        STDERR.puts "Skipping member #{member.class}"
      end
      context
    end

    # @param decl [RBS::AST::Declarations::Class]
    def class_decl_to_pin decl
      class_pin = Solargraph::Pin::Namespace.new(
        type: :class,
        name: decl.name.relative!.to_s,
        closure: Solargraph::Pin::ROOT_PIN,
        comments: decl.comment&.string
      )
      pins.push class_pin
      unless decl.super_class.nil?
        pins.push Solargraph::Pin::Reference::Superclass.new(
          closure: class_pin,
          name: decl.super_class.name.relative!.to_s
        )
      end
      convert_members_to_pin decl, class_pin
    end

    def module_decl_to_pin decl
      module_pin = Solargraph::Pin::Namespace.new(
        type: :module,
        name: decl.name.relative!.to_s,
        closure: Solargraph::Pin::ROOT_PIN,
        comments: decl.comment&.string
      )
      pins.push module_pin
      convert_members_to_pin decl, module_pin
    end

    # @param decl [RBS::AST::Declarations::Constant]
    def constant_decl_to_pin decl
      parts = decl.name.relative!.to_s.split('::')
      if parts.length > 1
        name = parts.last
        closure = pins.select { |pin| pin && pin.path == parts[0..-2].join('::') }.first
      else
        name = parts.first
        closure = Solargraph::Pin::ROOT_PIN
      end
      pin = Solargraph::Pin::Constant.new(
        name: name,
        closure: closure,
        comments: decl.comment&.string
      )
      pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', other_type_to_tag(decl.type)))
      pins.push pin
    end

    # @param decl [RBS::AST::Members::MethodDefinition]
    def method_def_to_pin decl, closure
      pin = Solargraph::Pin::Method.new(
        name: decl.name.to_s,
        closure: closure,
        comments: decl.comment&.string,
        scope: decl.instance? ? :instance : :class
      )
      # @todo This needs to be more robust. There will probably need to be a
      #   Pin::Method#definitions array of some kind of MethodDefinition object.
      if decl.types.length > 1
        pin.parameters.push Solargraph::Pin::Parameter.new(decl: :restarg, name: 'args', closure: pin)
      elsif decl.types.length > 0
        decl.types.first.type.required_positionals.each do |param|
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: param.name.to_s, closure: pin)
        end
        decl.types.first.type.optional_positionals.each do |param|
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :optarg, name: param.name.to_s, closure: pin)
        end
        if decl.types.first.type.rest_positionals
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :restarg, name: decl.types.first.type.rest_positionals.name.to_s, closure: pin)
        end
        decl.types.first.type.trailing_positionals.each do |param|
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: param.name.to_s, closure: pin)
        end
        decl.types.first.type.required_keywords.each do |name, param|
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :kwarg, name: name.to_s, closure: pin)
        end
        decl.types.first.type.optional_keywords.each do |name, param|
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :kwoptarg, name: name.to_s, closure: pin)
        end
        if decl.types.first.type.rest_keywords
          pin.parameters.push Solargraph::Pin::Parameter.new(decl: :kwrestarg, name: decl.types.first.type.rest_keywords.name.to_s, closure: pin)
        end
      end
      decl.types.each do |type|
        pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', method_type_to_tag(type)))
      end
      if pin.name == 'initialize' and pin.scope == :instance
        pins.push Solargraph::Pin::Method.new(
          location: pin.location,
          closure: pin.closure,
          name: 'new',
          comments: pin.comments,
          scope: :class,
          parameters: pin.parameters
        )
        # @todo Smelly instance variable access.
        pins.last.instance_variable_set(:@return_type, ComplexType::SELF)
        pin.instance_variable_set(:@visibility, :private)
        pin.instance_variable_set(:@return_type, ComplexType::VOID)
      end
      pins.push pin
    end

    def include_to_pin decl, closure
      pins.push Solargraph::Pin::Reference::Include.new(
        name: decl.name.relative!.to_s,
        closure: closure
      )
    end

    def alias_to_pin decl, closure
      pins.push Solargraph::Pin::MethodAlias.new(
        name: decl.new_name.to_s,
        original: decl.old_name.to_s,
        closure: closure
      )
    end

    def method_type_to_tag type
      "#{type.type.return_type}"
    end

    def other_type_to_tag type
      if type.is_a?(RBS::Types::Optional)
        "#{type.type.name.relative!}, nil"
      elsif type.is_a?(RBS::Types::Bases::Any)
        nil
      elsif type.is_a?(RBS::Types::Bases::Bool)
        'boolean'
      elsif type.is_a?(RBS::Types::Tuple)
        # @todo Figure this out
        nil
      elsif type.is_a?(RBS::Types::Literal)
        # @todo Figure this out
        nil
      elsif type.is_a?(RBS::Types::Union)
        # @todo Figure this out
        nil
      else
        type.name.relative!.to_s
      end
    end
  end
end
