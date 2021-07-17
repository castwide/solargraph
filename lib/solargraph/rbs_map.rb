require 'rbs'

class RbsMap
  class Region
    attr_reader :visibility

    def initialize visibility: :public
      @visibility = visibility
    end
  end
  attr_reader :pins

  def initialize
    loader = RBS::EnvironmentLoader.new
    # @type [RBS::Environment]
    environment = RBS::Environment.from_loader(loader).resolve_type_names
    environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
  end

  def pins
    @pins ||= []
  end

  private

  def convert_decl_to_pin decl, closure
    case decl
    when RBS::AST::Declarations::Class
      class_decl_to_pin(decl, closure)
    when RBS::AST::Declarations::Module
      module_decl_to_pin(decl, closure)
    when RBS::AST::Declarations::Constant
      constant_decl_to_pin(decl, closure)
    else
      STDERR.puts "Skipping declaration #{decl.class}"
    end
  end

  def convert_member_to_pin decl, closure, region
    case decl
    when RBS::AST::Members::MethodDefinition
      method_def_to_pin(decl, closure)
    when RBS::AST::Members::Include
      include_to_pin(decl, closure)
    when RBS::AST::Members::Alias
      alias_to_pin(decl, closure)
    when RBS::AST::Members::Public
      return Region.new(visibility: :public)
    when RBS::AST::Members::Private
      return Region.new(visibility: :private)
    # when RBS::AST::Members::Protected
    #   return Region.new(visibility: :protected)
    else
      STDERR.puts "Skipping member #{decl.class}"
    end
    region
  end

  # @param decl [RBS::AST::Declarations::Class]
  def class_decl_to_pin decl, closure
    pin = Solargraph::Pin::Namespace.new(
      type: :class,
      name: decl.name.relative!.to_s,
      closure: closure,
      comments: decl.comment&.string
    )
    pins.push pin
    region = Region.new
    decl.members.each do |mem|
      region = convert_member_to_pin(mem, pin, region)
    end
  end

  def module_decl_to_pin decl, closure
    pin = Solargraph::Pin::Namespace.new(
      type: :module,
      name: decl.name.relative!.to_s,
      closure: closure,
      comments: decl.comment&.string
    )
    pins.push pin
    region = Region.new
    decl.members.each do |mem|
      region = convert_member_to_pin(mem, pin, region)
    end
  end

  # @param decl [RBS::AST::Declarations::Constant]
  def constant_decl_to_pin decl, closure
    pin = Solargraph::Pin::Constant.new(
      name: decl.name.relative!.to_s,
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
      scope: decl.instance? ? :instance : :class,
    )
    pins.push pin
    decl.types.each do |type|
      pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', method_type_to_tag(type)))
    end
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
    else
      type.name.relative!.to_s
    end
  end
end
