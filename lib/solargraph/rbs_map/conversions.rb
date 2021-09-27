module Solargraph
  class RbsMap
    module Conversions
      class Context
        attr_reader :visibility
  
        # @param visibility [Symbol]
        def initialize visibility = :public
          @visibility = visibility
        end
      end

      def pins
        @pins ||= []
      end

      private

      def convert_decl_to_pin decl, closure
        cursor = pins.length
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
        pins[cursor..-1].each do |pin|
          pin.source = :rbs
          next unless pin.is_a?(Pin::Namespace) && pin.type == :class
          next if pins.any? { |p| p.path == "#{pin.path}.new"}
          pins.push Solargraph::Pin::Method.new(
            location: nil,
            closure: pin.closure,
            name: 'new',
            comments: pin.comments,
            scope: :class
          )
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
        when RBS::AST::Members::AttrReader
          attr_reader_to_pin(member, closure)
        when RBS::AST::Members::AttrWriter
          attr_writer_to_pin(member, closure)
        when RBS::AST::Members::AttrAccessor
          attr_accessor_to_pin(member, closure)
        when RBS::AST::Members::Include
          include_to_pin(member, closure)
        when RBS::AST::Members::Prepend
          prepend_to_pin(member, closure)
        when RBS::AST::Members::Extend
          extend_to_pin(member, closure)
        when RBS::AST::Members::Alias
          alias_to_pin(member, closure)
        when RBS::AST::Members::InstanceVariable
          ivar_to_pin(member, closure)
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
        update_pin_data(decl, pin)
        pins.push pin
      end
  
      def update_pin_data decl, pin
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
      end

      def attr_reader_to_pin(decl, closure)
        pin = Solargraph::Pin::Method.new(
          name: decl.name.to_s,
          closure: closure,
          comments: decl.comment&.string,
          scope: :instance,
          attribute: true
        )
        pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', other_type_to_tag(decl.type)))
        pins.push pin
      end

      def attr_writer_to_pin(decl, closure)
        pin = Solargraph::Pin::Method.new(
          name: "#{decl.name.to_s}=",
          closure: closure,
          comments: decl.comment&.string,
          scope: :instance,
          attribute: true
        )
        pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', other_type_to_tag(decl.type)))
        pins.push pin
      end

      def attr_accessor_to_pin(decl, closure)
        attr_reader_to_pin(decl, closure)
        attr_writer_to_pin(decl, closure)
      end

      def ivar_to_pin(decl, closure)
        pin = Solargraph::Pin::InstanceVariable.new(
          name: decl.name.to_s,
          closure: closure,
          comments: decl.comment&.string
        )
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', other_type_to_tag(decl.type)))
        pins.push pin
      end

      def include_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Include.new(
          name: decl.name.relative!.to_s,
          closure: closure
        )
      end
  
      def prepend_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Prepend.new(
          name: decl.name.relative!.to_s,
          closure: closure
        )
      end

      def extend_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Extend.new(
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
  
      RBS_TO_YARD_TYPE = {
        'bool' => 'Boolean',
        'string' => 'String',
        'untyped' => '',
        'NilClass' => 'nil'
      }

      def method_type_to_tag type
        str = "#{type.type.return_type}"
        RBS_TO_YARD_TYPE[str] || str
      end
  
      def other_type_to_tag type
        if type.is_a?(RBS::Types::Optional)
          "#{other_type_to_tag(type.type)}, nil"
        elsif type.is_a?(RBS::Types::Bases::Any)
          nil
        elsif type.is_a?(RBS::Types::Bases::Bool)
          'Boolean'
        elsif type.is_a?(RBS::Types::Tuple)
          # @todo Figure this out
          nil
        elsif type.is_a?(RBS::Types::Literal)
          # @todo Figure this out
          nil
        elsif type.is_a?(RBS::Types::Union)
          # @todo Figure this out
          nil
        elsif type.respond_to?(:name) && type.name.respond_to?(:relative!)
          RBS_TO_YARD_TYPE[type.name.relative!.to_s] || type.name.relative!.to_s
        else
          nil
        end
      end  
    end
  end
end
