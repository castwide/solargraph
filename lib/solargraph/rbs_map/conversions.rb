# frozen_string_literal: true

require 'rbs'

module Solargraph
  class RbsMap
    # Functions for converting RBS declarations to Solargraph pins
    #
    module Conversions
      # A container for tracking the current context of the RBS conversion
      # process, e.g., what visibility is declared for methods in the current
      # scope
      #
      class Context
        attr_reader :visibility

        # @param visibility [Symbol]
        def initialize visibility = :public
          @visibility = visibility
        end
      end

      # @return [Array<Pin::Base>]
      def pins
        @pins ||= []
      end

      private

      # @return [Hash{String => RBS::AST::Declarations::TypeAlias}]
      def type_aliases
        @type_aliases ||= {}
      end

      # @param loader [RBS::EnvironmentLoader]
      # @return [void]
      def load_environment_to_pins(loader)
        environment = RBS::Environment.from_loader(loader).resolve_type_names
        cursor = pins.length
        environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
        added_pins = pins[cursor..-1]
        add_back_implicit_pins(added_pins)
      end

      # @param added_pins [::Enumerable<Pin>]
      # @return [void]
      def add_back_implicit_pins(added_pins)
        added_pins.each do |pin|
          pin.source = :rbs
          next unless pin.is_a?(Pin::Namespace) && pin.type == :class
          next if pins.any? { |p| p.path == "#{pin.path}.new"}
          pins.push Solargraph::Pin::Method.new(
                      location: nil,
                      closure: pin,
                      name: 'new',
                      comments: pin.comments,
                      scope: :class
          )
        end
      end

      # @param decl [RBS::AST::Declarations::Base]
      # @param closure [Pin::Closure]
      # @return [void]
      def convert_decl_to_pin decl, closure
        case decl
        when RBS::AST::Declarations::Class
          class_decl_to_pin decl
        when RBS::AST::Declarations::Interface
          # STDERR.puts "Skipping interface #{decl.name.relative!}"
          interface_decl_to_pin decl
        when RBS::AST::Declarations::TypeAlias
          type_aliases[decl.name.to_s] = decl
        when RBS::AST::Declarations::Module
          module_decl_to_pin decl
        when RBS::AST::Declarations::Constant
          constant_decl_to_pin decl
        when RBS::AST::Declarations::ClassAlias
          class_alias_decl_to_pin decl
        else
          Solargraph.logger.info "Skipping declaration #{decl.class}"
        end
      end

      # @param decl [RBS::AST::Declarations::Module, RBS::AST::Declarations::Class, RBS::AST::Declarations::Interface]
      # @param closure [Pin::Namespace]
      # @return [void]
      def convert_members_to_pin decl, closure
        context = Context.new
        decl.members.each { |m| context = convert_member_to_pin(m, closure, context) }
      end

      # @param member [RBS::AST::Members::Base,RBS::AST::Declarations::Base]
      # @param closure [Pin::Namespace]
      # @param context [Context]
      # @return [void]
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
          Solargraph.logger.warn "Skipping member type #{member.class}"
        end
        context
      end

      # @param decl [RBS::AST::Declarations::Class]
      # @return [void]
      def class_decl_to_pin decl
        class_pin = Solargraph::Pin::Namespace.new(
          type: :class,
          name: decl.name.relative!.to_s,
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          generics: decl.type_params.map(&:name).map(&:to_s)
        )
        pins.push class_pin
        if decl.super_class
          pins.push Solargraph::Pin::Reference::Superclass.new(
            closure: class_pin,
            name: decl.super_class.name.relative!.to_s
          )
        end
        convert_members_to_pin decl, class_pin
      end

      # @param decl [RBS::AST::Declarations::Interface]
      # @return [void]
      def interface_decl_to_pin decl
        class_pin = Solargraph::Pin::Namespace.new(
          type: :module,
          name: decl.name.relative!.to_s,
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          # HACK: Using :hidden to keep interfaces from appearing in
          # autocompletion
          visibility: :hidden
        )
        class_pin.docstring.add_tag(YARD::Tags::Tag.new(:abstract, '(RBS interface)'))
        pins.push class_pin
        convert_members_to_pin decl, class_pin
      end

      # @param decl [RBS::AST::Declarations::Module]
      # @return [void]
      def module_decl_to_pin decl
        module_pin = Solargraph::Pin::Namespace.new(
          type: :module,
          name: decl.name.relative!.to_s,
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          generics: decl.type_params.map(&:name).map(&:to_s),
        )
        pins.push module_pin
        convert_members_to_pin decl, module_pin
      end

      # @param name [String]
      # @param tag [String]
      # @param comments [String]
      #
      # @return [Solargraph::Pin::Constant]
      def create_constant(name, tag, comments)
        parts = name.split('::')
        if parts.length > 1
          name = parts.last
          closure = pins.select { |pin| pin && pin.path == parts[0..-2].join('::') }.first
        else
          name = parts.first
          closure = Solargraph::Pin::ROOT_PIN
        end
        constant_pin = Solargraph::Pin::Constant.new(
          name: name,
          closure: closure,
          comments: comments
        )
        # @todo Class or Module?
        constant_pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', "Class<#{tag}>"))
        constant_pin
      end

      # @param decl [RBS::AST::Declarations::ClassAlias]
      # @return [void]
      def class_alias_decl_to_pin decl
        # See https://www.rubydoc.info/gems/rbs/3.4.3/RBS/AST/Declarations/ClassAlias
        new_name = decl.new_name.relative!.to_s
        old_name = decl.old_name.relative!.to_s

        pins.push create_constant(new_name, old_name, decl.comment&.string)
      end

      # @param decl [RBS::AST::Declarations::Constant]
      # @return [void]
      def constant_decl_to_pin decl
        tag = other_type_to_tag(decl.type)
        pins.push create_constant(decl.name.relative!.to_s, tag, decl.comment&.string)
      end

      # @param decl [RBS::AST::Members::MethodDefinition]
      # @param closure [Pin::Closure]
      # @return [void]
      def method_def_to_pin decl, closure
        # there may be edge cases here around different signatures
        # having different type params / orders - we may need to match
        # this data model and have generics live in signatures to
        # handle those correctly
        generics = decl.overloads.map(&:method_type).flat_map(&:type_params).map(&:name).map(&:to_s).uniq
        if decl.instance?
          pin = Solargraph::Pin::Method.new(
            name: decl.name.to_s,
            closure: closure,
            comments: decl.comment&.string,
            scope: :instance,
            signatures: [],
            generics: generics,
          )
          pin.signatures.concat method_def_to_sigs(decl, pin)
          pins.push pin
          if pin.name == 'initialize'
            pins.push Solargraph::Pin::Method.new(
              location: pin.location,
              closure: pin.closure,
              name: 'new',
              comments: pin.comments,
              scope: :class,
              signatures: pin.signatures
            )
            pins.last.signatures.replace(
              pin.signatures.map do |p|
                Pin::Signature.new(
                  p.parameters,
                  ComplexType::SELF
                )
              end
            )
            # @todo Is this necessary?
            # pin.instance_variable_set(:@visibility, :private)
            # pin.instance_variable_set(:@return_type, ComplexType::VOID)
          end
        end
        if decl.singleton?
          pin = Solargraph::Pin::Method.new(
            name: decl.name.to_s,
            closure: closure,
            comments: decl.comment&.string,
            scope: :class,
            signatures: [],
            generics: generics,
          )
          pin.signatures.concat method_def_to_sigs(decl, pin)
          pins.push pin
        end
      end

      # @param decl [RBS::AST::Members::MethodDefinition]
      # @param pin [Pin::Method]
      # @return [void]
      def method_def_to_sigs decl, pin
        decl.overloads.map do |overload|
          parameters, return_type = parts_of_function(overload.method_type, pin)
          block = if overload.method_type.block
                    Pin::Signature.new(*parts_of_function(overload.method_type.block, pin))
          end
          return_type = ComplexType.try_parse(method_type_to_tag(overload.method_type))
          Pin::Signature.new(parameters, return_type, block)
        end
      end

      # @param type [RBS::MethodType,RBS::Types::Block]
      # @param pin [Pin::Method]
      # @return [Array<Array<Pin::Parameter>, ComplexType>]
      def parts_of_function type, pin
        return [[Solargraph::Pin::Parameter.new(decl: :restarg, name: 'arg', closure: pin)], ComplexType.try_parse(method_type_to_tag(type))] if defined?(RBS::Types::UntypedFunction) && type.type.is_a?(RBS::Types::UntypedFunction)

        parameters = []
        arg_num = -1
        type.type.required_positionals.each do |param|
          name = param.name ? param.name.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: name, closure: pin, return_type: ComplexType.try_parse(other_type_to_tag(param.type)))
        end
        type.type.optional_positionals.each do |param|
          name = param.name ? param.name.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :optarg, name: name, closure: pin,
                                                         return_type: ComplexType.try_parse(other_type_to_tag(param.type)))
        end
        if type.type.rest_positionals
          name = type.type.rest_positionals.name ? type.type.rest_positionals.name.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :restarg, name: name, closure: pin)
        end
        type.type.trailing_positionals.each do |param|
          name = param.name ? param.name.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: name, closure: pin)
        end
        type.type.required_keywords.each do |orig, param|
          name = orig ? orig.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwarg, name: name, closure: pin,
                                                         return_type: ComplexType.try_parse(other_type_to_tag(param.type)))
        end
        type.type.optional_keywords.each do |orig, param|
          name = orig ? orig.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwoptarg, name: name, closure: pin,
                                                         return_type: ComplexType.try_parse(other_type_to_tag(param.type)))
        end
        if type.type.rest_keywords
          name = type.type.rest_keywords.name ? type.type.rest_keywords.name.to_s : "arg#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwrestarg, name: type.type.rest_keywords.name.to_s, closure: pin)
        end
        return_type = ComplexType.try_parse(method_type_to_tag(type))
        [parameters, return_type]
      end

      # @param decl [RBS::AST::Members::AttrReader,RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @return [void]
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

      # @param decl [RBS::AST::Members::AttrWriter, RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @return [void]
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

      # @param decl [RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @return [void]
      def attr_accessor_to_pin(decl, closure)
        attr_reader_to_pin(decl, closure)
        attr_writer_to_pin(decl, closure)
      end

      # @param decl [RBS::AST::Members::InstanceVariable]
      # @param closure [Pin::Namespace]
      # @return [void]
      def ivar_to_pin(decl, closure)
        pin = Solargraph::Pin::InstanceVariable.new(
          name: decl.name.to_s,
          closure: closure,
          comments: decl.comment&.string
        )
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', other_type_to_tag(decl.type)))
        pins.push pin
      end

      # @param decl [RBS::AST::Members::Include]
      # @param closure [Pin::Namespace]
      # @return [void]
      def include_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Include.new(
          name: decl.name.relative!.to_s,
          closure: closure
        )
      end

      # @param decl [RBS::AST::Members::Prepend]
      # @param closure [Pin::Namespace]
      # @return [void]
      def prepend_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Prepend.new(
          name: decl.name.relative!.to_s,
          closure: closure
        )
      end

      # @param decl [RBS::AST::Members::Extend]
      # @param closure [Pin::Namespace]
      # @return [void]
      def extend_to_pin decl, closure
        pins.push Solargraph::Pin::Reference::Extend.new(
          name: decl.name.relative!.to_s,
          closure: closure
        )
      end

      # @param decl [RBS::AST::Members::Alias]
      # @param closure [Pin::Namespace]
      # @return [void]
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
        'int' => 'Integer',
        'untyped' => '',
        'NilClass' => 'nil'
      }

      # @param type [RBS::MethodType]
      # @return [String]
      def method_type_to_tag type
        if type_aliases.key?(type.type.return_type.to_s)
          other_type_to_tag(type_aliases[type.type.return_type.to_s].type)
        else
          other_type_to_tag type.type.return_type
        end
      end

      # @param type [Object]
      # @return [String]
      def other_type_to_tag type
        if type.is_a?(RBS::Types::Optional)
          "#{other_type_to_tag(type.type)}, nil"
        elsif type.is_a?(RBS::Types::Bases::Any)
          # @todo Not sure what to do with Any yet
          'BasicObject'
        elsif type.is_a?(RBS::Types::Bases::Bool)
          'Boolean'
        elsif type.is_a?(RBS::Types::Tuple)
          "Array(#{type.types.map { |t| other_type_to_tag(t) }.join(', ')})"
        elsif type.is_a?(RBS::Types::Literal)
          "#{type.literal}"
        elsif type.is_a?(RBS::Types::Union)
          type.types.map { |t| other_type_to_tag(t) }.join(', ')
        elsif type.is_a?(RBS::Types::Record)
          # @todo Better record support
          'Hash'
        elsif type.is_a?(RBS::Types::Bases::Nil)
          'nil'
        elsif type.is_a?(RBS::Types::Bases::Self)
          'self'
        elsif type.is_a?(RBS::Types::Bases::Void)
          'void'
        elsif type.is_a?(RBS::Types::Variable)
          "#{Solargraph::ComplexType::GENERIC_TAG_NAME}<#{type.name}>"
        elsif type.is_a?(RBS::Types::ClassInstance) #&& !type.args.empty?
          base = RBS_TO_YARD_TYPE[type.name.relative!.to_s] || type.name.relative!.to_s
          params = type.args.map { |a| other_type_to_tag(a) }.reject { |t| t == 'undefined' }
          return base if params.empty?
          "#{base}<#{params.join(', ')}>"
        elsif type.is_a?(RBS::Types::Bases::Instance)
          'self'
        elsif type.is_a?(RBS::Types::Bases::Top)
          # top is the most super superclass
          'BasicObject'
        elsif type.is_a?(RBS::Types::Bases::Bottom)
          # bottom is used in contexts where nothing will ever return
          # - e.g., it could be the return type of 'exit()' or 'raise'
          #
          # @todo define a specific bottom type and use it to
          #   determine dead code
          'undefined'
        elsif type.is_a?(RBS::Types::Intersection)
          type.types.map { |member| other_type_to_tag(member) }.join(', ')
        elsif type.is_a?(RBS::Types::Proc)
          'Proc'
        elsif type.respond_to?(:name) && type.name.respond_to?(:relative!)
          RBS_TO_YARD_TYPE[type.name.relative!.to_s] || type.name.relative!.to_s
        else
          Solargraph.logger.warn "Unrecognized RBS type: #{type.class} at #{type.location}"
          'undefined'
        end
      end
    end
  end
end
