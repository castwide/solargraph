# frozen_string_literal: true

require 'rbs'

module Solargraph
  class RbsMap
    # Functions for converting RBS declarations to Solargraph pins
    #
    class Conversions
      include Logging

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

      # @param loader [RBS::EnvironmentLoader]
      def initialize loader:
        @loader = loader
        @pins = []
        load_environment_to_pins(loader)
      end

      # @return [RBS::EnvironmentLoader]
      attr_reader :loader

      # @return [Array<Pin::Base>]
      attr_reader :pins

      private

      # @param loader [RBS::EnvironmentLoader]
      #
      # @return [void]
      def load_environment_to_pins loader
        environment = RBS::Environment.from_loader(loader).resolve_type_names
        if environment.declarations.empty?
          Solargraph.logger.info 'No RBS declarations found in environment for core_root ' \
                                 "#{loader.core_root.inspect}, libraries #{loader.libs} and " \
                                 "directories #{loader.dirs}"
          return
        end
        environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
      end

      # @param decl [RBS::AST::Declarations::Base]
      # @param closure [Pin::Closure]
      # @return [void]
      def convert_decl_to_pin decl, closure
        case decl
        when RBS::AST::Declarations::Class
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.name.absolute?
            Solargraph.assert_or_log(:rbs_closure, "Ignoring closure #{closure.inspect} on class #{decl.inspect}")
          end
          class_decl_to_pin decl
        when RBS::AST::Declarations::Interface
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.name.absolute?
            Solargraph.assert_or_log(:rbs_closure, "Ignoring closure #{closure.inspect} on interface #{decl.inspect}")
          end
          # STDERR.puts "Skipping interface #{decl.name.relative!}"
          interface_decl_to_pin decl
        when RBS::AST::Declarations::TypeAlias
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.name.absolute?
            Solargraph.assert_or_log(:rbs_closure,
                                     # @sg-ignore flow sensitive typing should support case/when
                                     "Ignoring closure #{closure.inspect} on alias type name #{decl.name}")
          end
          pins.push(
            # @sg-ignore Wrong argument type for Solargraph::Pin::Reference::TypeAlias.new: return_type expected Solargraph::ComplexType, received Solargraph::ComplexType::UniqueType, Solargraph::ComplexType
            Solargraph::Pin::Reference::TypeAlias.new(
              # @sg-ignore Unresolved calls to name, type, type_location; return_type type mismatch
              name: ComplexType.try_parse(decl.name.to_s).to_s, return_type: other_type_to_type(decl.type).force_rooted, closure: closure, source: :rbs, type_location: location_decl_to_pin_location(decl.location)
            )
          )
        when RBS::AST::Declarations::Module
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.name.absolute?
            Solargraph.assert_or_log(:rbs_closure,
                                     # @sg-ignore flow sensitive typing should support case/when
                                     "Ignoring closure #{closure.inspect} on alias type name #{decl.name}")
          end
          module_decl_to_pin decl
        when RBS::AST::Declarations::Constant
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.name.absolute?
            Solargraph.assert_or_log(:rbs_closure, "Ignoring closure #{closure.inspect} on constant #{decl.inspect}")
          end
          constant_decl_to_pin decl
        when RBS::AST::Declarations::ClassAlias
          # @sg-ignore flow sensitive typing should support case/when
          unless closure.name == '' || decl.new_name.absolute?
            Solargraph.assert_or_log(:rbs_closure, "Ignoring closure #{closure.inspect} on class alias #{decl.inspect}")
          end
          class_alias_decl_to_pin decl
        when RBS::AST::Declarations::ModuleAlias
          unless closure.name == ''
            Solargraph.assert_or_log(:rbs_closure,
                                     "Ignoring closure #{closure.inspect} on module alias #{decl.inspect}")
          end
          module_alias_decl_to_pin decl
        when RBS::AST::Declarations::Global
          unless closure.name == ''
            Solargraph.assert_or_log(:rbs_closure, "Ignoring closure #{closure.inspect} on global decl #{decl.inspect}")
          end
          global_decl_to_pin decl
        else
          Solargraph.logger.warn "Skipping declaration #{decl.class}"
        end
      end

      # @param decl [RBS::AST::Declarations::Module]
      # @param module_pin [Pin::Namespace]
      # @return [void]
      def convert_self_types_to_pins decl, module_pin
        decl.self_types.each { |self_type| convert_self_type_to_pins(self_type, module_pin) }
      end

      # @type [Hash{String => String}]
      RBS_TO_CLASS = {
        'bool' => 'Boolean',
        'string' => 'String',
        'int' => 'Integer'
      }.freeze
      private_constant :RBS_TO_CLASS

      # rooted names (namespaces) use the prefix of :: when they are
      # relative to the root namespace, or not if they are relative to
      # the current namespace.
      #
      # @param type_name [RBS::TypeName]
      #
      # @return [String]
      def rooted_name type_name
        name = type_name.to_s
        RBS_TO_CLASS.fetch(name, name)
      end

      # fqns names are implicitly fully qualified - they are relative
      # to the root namespace and are not prefixed with ::
      #
      # @param type_name [RBS::TypeName]
      #
      # @return [String]
      def fqns type_name
        unless type_name.absolute?
          Solargraph.assert_or_log(:rbs_fqns, "Received unexpected unqualified type name: #{type_name}")
        end
        ns = type_name.relative!.to_s
        RBS_TO_CLASS.fetch(ns, ns)
      end

      # @param type_name [RBS::TypeName]
      # @param type_args [Enumerable<RBS::Types::Bases::Base>]
      # @return [ComplexType::UniqueType]
      def build_type type_name, type_args = []
        # we use .absolute? below to tell the type object what to
        # expect
        rbs_name = type_name.relative!.to_s
        base = RBS_TO_CLASS.fetch(rbs_name, rbs_name)

        params = type_args.map { |a| other_type_to_type(a) }
        # tuples have their own class and are handled in other_type_to_type
        if base == 'Hash' && params.length == 2
          ComplexType::UniqueType.new(base, [params.first], [params.last], rooted: type_name.absolute?,
                                                                           parameters_type: :hash)
        else
          ComplexType::UniqueType.new(base, [], params.reject(&:undefined?), rooted: type_name.absolute?,
                                                                             parameters_type: :list)
        end
      end

      # @param decl [RBS::AST::Declarations::Module::Self]
      # @param closure [Pin::Namespace]
      # @return [void]
      def convert_self_type_to_pins decl, closure
        type = build_type(decl.name, decl.args)
        generic_values = type.all_params.map(&:rooted_tags)
        include_pin = Solargraph::Pin::Reference::Include.new(
          name: type.name,
          type_location: location_decl_to_pin_location(decl.location),
          generic_values: generic_values,
          closure: closure,
          source: :rbs
        )
        pins.push include_pin
      end

      # @param decl [RBS::AST::Declarations::Module,RBS::AST::Declarations::Class,RBS::AST::Declarations::Interface]
      # @param closure [Pin::Namespace]
      # @return [void]
      def convert_members_to_pins decl, closure
        context = Conversions::Context.new
        decl.members.each { |m| context = convert_member_to_pin(m, closure, context) }
      end

      # @param member [RBS::AST::Members::Base,RBS::AST::Declarations::Base]
      # @param closure [Pin::Namespace]
      # @param context [Context]
      # @return [Context]
      def convert_member_to_pin member, closure, context
        case member
        when RBS::AST::Members::MethodDefinition
          # @sg-ignore flow based typing needs to understand case when class pattern
          method_def_to_pin(member, closure, context)
        when RBS::AST::Members::AttrReader
          # @sg-ignore flow based typing needs to understand case when class pattern
          attr_reader_to_pin(member, closure, context)
        when RBS::AST::Members::AttrWriter
          # @sg-ignore flow based typing needs to understand case when class pattern
          attr_writer_to_pin(member, closure, context)
        when RBS::AST::Members::AttrAccessor
          # @sg-ignore flow based typing needs to understand case when class pattern
          attr_accessor_to_pin(member, closure, context)
        when RBS::AST::Members::Include
          # @sg-ignore flow based typing needs to understand case when class pattern
          include_to_pin(member, closure)
        when RBS::AST::Members::Prepend
          # @sg-ignore flow based typing needs to understand case when class pattern
          prepend_to_pin(member, closure)
        when RBS::AST::Members::Extend
          # @sg-ignore flow based typing needs to understand case when class pattern
          extend_to_pin(member, closure)
        when RBS::AST::Members::Alias
          # @sg-ignore flow based typing needs to understand case when class pattern
          alias_to_pin(member, closure)
        when RBS::AST::Members::ClassInstanceVariable
          # @sg-ignore flow based typing needs to understand case when class pattern
          civar_to_pin(member, closure)
        when RBS::AST::Members::ClassVariable
          # @sg-ignore flow based typing needs to understand case when class pattern
          cvar_to_pin(member, closure)
        when RBS::AST::Members::InstanceVariable
          # @sg-ignore flow based typing needs to understand case when class pattern
          ivar_to_pin(member, closure)
        when RBS::AST::Members::Public
          return Context.new(:public)
        when RBS::AST::Members::Private
          return Context.new(:private)
        when RBS::AST::Declarations::Base
          # @sg-ignore flow based typing needs to understand case when class pattern
          convert_decl_to_pin(member, closure)
        else
          Solargraph.logger.warn "Skipping member type #{member.class}"
        end
        context
      end

      # Pull the name of type variables for a generic - not the
      # values, the names (e.g., T, U, V).  As such, "rooting" isn't a
      # thing, these are all in the global namespace.
      #
      # @param decl [RBS::AST::Declarations::Class, RBS::AST::Declarations::Interface,
      #   RBS::AST::Declarations::Module, RBS::MethodType]
      #
      # @return [Array<String>]
      def type_parameter_names decl
        decl.type_params.map(&:name).map(&:to_s)
      end

      # @param decl [RBS::AST::Declarations::Class]
      # @return [void]
      def class_decl_to_pin decl
        # @type [Hash{String => ComplexType, ComplexType::UniqueType}]
        generic_defaults = {}
        decl.type_params.each do |param|
          generic_defaults[param.name.to_s] = other_type_to_type param.default_type if param.default_type
        end

        class_name = fqns(decl.name)

        generics = type_parameter_names(decl)

        class_pin = Solargraph::Pin::Namespace.new(
          type: :class,
          name: class_name,
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          type_location: location_decl_to_pin_location(decl.location),
          # @todo some type parameters in core/stdlib have default
          #   values; Solargraph doesn't support that yet as so these
          #   get treated as undefined if not specified
          generics: generics,
          generic_defaults: generic_defaults,
          source: :rbs
        )
        pins.push class_pin
        if decl.super_class
          type = build_type(decl.super_class.name, decl.super_class.args)
          generic_values = type.all_params.map(&:rooted_tags)
          pins.push Solargraph::Pin::Reference::Superclass.new(
            type_location: location_decl_to_pin_location(decl.super_class.location),
            closure: class_pin,
            generic_values: generic_values,
            name: type.rooted_name, # reference pins use rooted names
            source: :rbs
          )
        end
        add_mixins decl, class_pin
        convert_members_to_pins decl, class_pin
      end

      # @param decl [RBS::AST::Declarations::Interface]
      # @return [void]
      def interface_decl_to_pin decl
        class_pin = Solargraph::Pin::Namespace.new(
          type: :module,
          type_location: location_decl_to_pin_location(decl.location),
          name: fqns(decl.name),
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          generics: type_parameter_names(decl),
          # HACK: Using :hidden to keep interfaces from appearing in
          # autocompletion
          visibility: :hidden,
          source: :rbs
        )
        class_pin.docstring.add_tag(YARD::Tags::Tag.new(:abstract, '(RBS interface)'))
        pins.push class_pin
        convert_members_to_pins decl, class_pin
      end

      # @param decl [RBS::AST::Declarations::Module]
      # @return [void]
      def module_decl_to_pin decl
        module_pin = Solargraph::Pin::Namespace.new(
          type: :module,
          name: fqns(decl.name),
          type_location: location_decl_to_pin_location(decl.location),
          closure: Solargraph::Pin::ROOT_PIN,
          comments: decl.comment&.string,
          generics: type_parameter_names(decl),
          source: :rbs
        )
        pins.push module_pin
        convert_self_types_to_pins decl, module_pin
        convert_members_to_pins decl, module_pin

        raise "Invalid type for module declaration: #{module_pin.class}" unless module_pin.is_a?(Pin::Namespace)

        add_mixins decl, module_pin.closure
      end

      # @param fqns [String]
      # @param type [ComplexType, ComplexType::UniqueType]
      # @param comments [String, nil]
      # @param decl [RBS::AST::Declarations::ClassAlias,
      #   RBS::AST::Declarations::Constant,
      #   RBS::AST::Declarations::ModuleAlias]
      # @param base [String, nil] Optional conversion of tag to
      #   base<tag> - valid values are Class and Module
      #
      # @return [Solargraph::Pin::Constant]
      def create_constant fqns, type, comments, decl, base = nil
        parts = fqns.split('::')
        if parts.length > 1
          fqns = parts.last
          # @sg-ignore Need to add nil check here
          closure = pins.select { |pin| pin && pin.path == parts[0..-2].join('::') }.first
        else
          fqns = parts.first
          closure = Solargraph::Pin::ROOT_PIN
        end
        constant_pin = Solargraph::Pin::Constant.new(
          name: fqns,
          closure: closure,
          type_location: location_decl_to_pin_location(decl.location),
          comments: comments,
          source: :rbs
        )
        rooted_tag = type.rooted_tags
        rooted_tag = "#{base}<#{rooted_tag}>" if base
        constant_pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', rooted_tag))
        constant_pin
      end

      # @param decl [RBS::AST::Declarations::ClassAlias]
      # @return [void]
      def class_alias_decl_to_pin decl
        # See https://www.rubydoc.info/gems/rbs/3.4.3/RBS/AST/Declarations/ClassAlias
        new_name = fqns(decl.new_name)
        old_type = build_type(decl.old_name)
        pins.push create_constant(new_name, old_type, decl.comment&.string, decl, '::Class')
      end

      # @param decl [RBS::AST::Declarations::ModuleAlias]
      # @return [void]
      def module_alias_decl_to_pin decl
        # See https://www.rubydoc.info/gems/rbs/3.4.3/RBS/AST/Declarations/ModuleAlias
        new_name = fqns(decl.new_name)
        old_type = build_type(decl.old_name)

        pins.push create_constant(new_name, old_type, decl.comment&.string, decl, '::Module')
      end

      # @param decl [RBS::AST::Declarations::Constant]
      # @return [void]
      def constant_decl_to_pin decl
        target_type = other_type_to_type(decl.type)
        constant_name = fqns(decl.name)
        pins.push create_constant(constant_name, target_type, decl.comment&.string, decl)
      end

      # @param decl [RBS::AST::Declarations::Global]
      # @return [void]
      def global_decl_to_pin decl
        closure = Solargraph::Pin::ROOT_PIN
        name = decl.name.to_s
        pin = Solargraph::Pin::GlobalVariable.new(
          name: name,
          closure: closure,
          comments: decl.comment&.string,
          type_location: location_decl_to_pin_location(decl.location),
          source: :rbs
        )
        rooted_tag = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', rooted_tag))
        pins.push pin
      end

      # Visibility overrides that will allow the Solargraph project
      # and plugins to pass typechecking using SOLARGRAPH_ASSERTS=on,
      # so that we can detect any regressions/issues elsewhere in the
      # visibility logic.
      #
      # These should either reflect a bug upstream in the RBS
      # definitions, or include a @todo indicating what needs to be
      # fixed in Solargraph to properly understand it.
      #
      # @todo PR these fixes upstream and list open PRs here above
      #   related overrides
      # @todo externalize remaining overrides into yaml file, then
      #   allow that to be extended via .solargraph.yml
      # @type [Hash{Array(String, Symbol, String) => Symbol}
      VISIBILITY_OVERRIDE = {
        ['Rails::Engine', :instance, 'run_tasks_blocks'] => :protected,
        # Should have been marked as both instance and class method in module -e.g., 'module_function'
        ['Kernel', :instance, 'pretty_inspect'] => :private,
        # marked incorrectly in RBS
        ['WEBrick::HTTPUtils::FormData', :instance, 'next_data'] => :protected,
        ['Rails::Command', :class, 'command_type'] => :private,
        ['Rails::Command', :class, 'lookup_paths'] => :private,
        ['Rails::Command', :class, 'file_lookup_paths'] => :private,
        ['Rails::Railtie', :instance, 'run_console_blocks'] => :protected,
        ['Rails::Railtie', :instance, 'run_generators_blocks'] => :protected,
        ['Rails::Railtie', :instance, 'run_runner_blocks'] => :protected,
        ['Rails::Railtie', :instance, 'run_tasks_blocks'] => :protected,
        ['ActionController::Base', :instance, '_protected_ivars'] => :private,
        ['ActionView::Template', :instance, 'method_name'] => :public,
        ['Module', :instance, 'ruby2_keywords'] => :private,
        ['Nokogiri::XML::Node', :instance, 'coerce'] => :protected,
        ['Nokogiri::XML::Document', :class, 'empty_doc?'] => :private,
        ['Nokogiri::Decorators::Slop', :instance, 'respond_to_missing?'] => :public,
        ['RuboCop::Cop::RangeHelp', :instance, 'source_range'] => :private,
        ['AST::Node', :instance, 'original_dup'] => :private,
        ['Rainbow::Presenter', :instance, 'wrap_with_sgr'] => :private
      }.freeze
      private_constant :VISIBILITY_OVERRIDE

      # @param decl [RBS::AST::Members::MethodDefinition, RBS::AST::Members::AttrReader,
      #   RBS::AST::Members::AttrWriter, RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Closure]
      # @param context [Context]
      # @param scope [Symbol] :instance or :class
      # @param name [String] The name of the method
      # @return [Symbol]
      # @sg-ignore Declared return type ::Symbol does not match inferred type
      #   ::Symbol, :public, :private, nil for Solargraph::RbsMap::Conversions#calculate_method_visibility
      def calculate_method_visibility decl, context, closure, scope, name
        override_key = [closure.path, scope, name]
        visibility = VISIBILITY_OVERRIDE[override_key]
        simple_override_key = [closure.path, scope]
        visibility ||= VISIBILITY_OVERRIDE[simple_override_key]
        if closure.path == 'Kernel' && Kernel.private_method_defined?(decl.name, false)
          visibility ||= :private
        end
        if decl.kind == :singleton_instance
          # this is a 'module function'
          visibility ||= :private
        end
        visibility ||= decl.visibility
        visibility ||= context.visibility
        visibility ||= :public
        visibility
      end

      # @param decl [RBS::AST::Members::MethodDefinition]
      # @param closure [Pin::Closure]
      # @param context [Context]
      # @return [void]
      def method_def_to_pin decl, closure, context
        # there may be edge cases here around different signatures
        # having different type params / orders - we may need to match
        # this data model and have generics live in signatures to
        # handle those correctly
        generics = decl.overloads.map(&:method_type).map do |method_type|
          type_parameter_names method_type
        end

        if decl.instance?
          name = decl.name.to_s
          final_scope = :instance
          visibility = calculate_method_visibility(decl, context, closure, final_scope, name)
          pin = Solargraph::Pin::Method.new(
            name: name,
            closure: closure,
            type_location: location_decl_to_pin_location(decl.location),
            comments: decl.comment&.string,
            scope: final_scope,
            signatures: [],
            generics: generics,
            visibility: visibility,
            source: :rbs
          )
          pin.signatures.concat method_def_to_sigs(decl, pin)
          pins.push pin
          if pin.name == 'initialize'
            pin.instance_variable_set(:@visibility, :private)
            pin.instance_variable_set(:@return_type, ComplexType::VOID)
          end
        end
        return unless decl.singleton?
        final_scope = :class
        name = decl.name.to_s
        visibility = calculate_method_visibility(decl, context, closure, final_scope, name)
        pin = Solargraph::Pin::Method.new(
          name: name,
          closure: closure,
          comments: decl.comment&.string,
          type_location: location_decl_to_pin_location(decl.location),
          visibility: visibility,
          scope: final_scope,
          signatures: [],
          generics: generics,
          source: :rbs
        )
        pin.signatures.concat method_def_to_sigs(decl, pin)
        pins.push pin
      end

      # @param decl [RBS::AST::Members::MethodDefinition]
      # @param pin [Pin::Method]
      # @return [void]
      def method_def_to_sigs decl, pin
        # rubocop:disable Style/SafeNavigationChainLength
        implicit_nil = decl.overloads.first&.annotations&.map(&:string)&.include?('implicitly-returns-nil')
        # rubocop:enable Style/SafeNavigationChainLength
        # @param overload [RBS::AST::Members::MethodDefinition::Overload]
        decl.overloads.map do |overload|
          # @sg-ignore Wrong argument type for Solargraph::RbsMap::Conversions#location_decl_to_pin_location:
          #   location expected RBS::Location, nil, received RBS::Location<:type, :type_params>, RBS::AST::Members::Attribute::loc, nil
          type_location = location_decl_to_pin_location(overload.method_type.location)
          generics = type_parameter_names(overload.method_type)
          signature_parameters, signature_return_type = parts_of_function(overload.method_type, pin, implicit_nil)
          rbs_block = overload.method_type.block
          block = if rbs_block
                    block_parameters, block_return_type = parts_of_function(rbs_block, pin, implicit_nil)
                    Pin::Signature.new(generics: generics, parameters: block_parameters,
                                       return_type: block_return_type, source: :rbs,
                                       type_location: type_location, closure: pin)
                  end
          Pin::Signature.new(generics: generics, parameters: signature_parameters,
                             return_type: signature_return_type, block: block, source: :rbs,
                             type_location: type_location, closure: pin)
        end
      end

      # @param location [RBS::Location, nil]
      # @return [Solargraph::Location, nil]
      def location_decl_to_pin_location location
        return nil if location&.name.nil?

        # @sg-ignore flow sensitive typing should handle return nil if location&.name.nil?
        start_pos = Position.new(location.start_line - 1, location.start_column)
        # @sg-ignore flow sensitive typing should handle return nil if location&.name.nil?
        end_pos = Position.new(location.end_line - 1, location.end_column)
        range = Range.new(start_pos, end_pos)
        # @sg-ignore flow sensitve typing should handle return nil if location&.name.nil?
        Location.new(location.name.to_s, range)
      end

      # @param type [RBS::MethodType, RBS::Types::Block]
      # @param pin [Pin::Method]
      # @param implicit_nil [Boolean]
      # @return [Array(Array<Pin::Parameter>, ComplexType)]
      def parts_of_function type, pin, implicit_nil
        type_location = pin.type_location
        if defined?(RBS::Types::UntypedFunction) && type.type.is_a?(RBS::Types::UntypedFunction)
          return [
            [Solargraph::Pin::Parameter.new(decl: :restarg, name: 'arg', closure: pin, source: :rbs,
                                            type_location: type_location)],
            method_type_to_type(type, implicit_nil)
          ]
        end

        parameters = []
        arg_num = -1
        type.type.required_positionals.each do |param|
          # @sg-ignore Unresolved call to name
          name = param.name ? param.name.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: name, closure: pin,
                                                         # @sg-ignore RBS generic type understanding issue
                                                         return_type: other_type_to_type(param.type),
                                                         source: :rbs, type_location: type_location)
        end
        type.type.optional_positionals.each do |param|
          # @sg-ignore Unresolved call to name
          name = param.name ? param.name.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :optarg, name: name, closure: pin,
                                                         # @sg-ignore RBS generic type understanding issue
                                                         return_type: other_type_to_type(param.type),
                                                         type_location: type_location,
                                                         source: :rbs)
        end
        if type.type.rest_positionals
          name = type.type.rest_positionals.name ? type.type.rest_positionals.name.to_s : "arg_#{arg_num += 1}"
          inner_rest_positional_type = other_type_to_type(type.type.rest_positionals.type)
          rest_positional_type = ComplexType::UniqueType.new('Array',
                                                             [],
                                                             [inner_rest_positional_type],
                                                             rooted: true, parameters_type: :list)
          parameters.push Solargraph::Pin::Parameter.new(decl: :restarg, name: name, closure: pin,
                                                         source: :rbs, type_location: type_location,
                                                         return_type: rest_positional_type)
        end
        type.type.trailing_positionals.each do |param|
          # @sg-ignore Unresolved call to name
          name = param.name ? param.name.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :arg, name: name, closure: pin, source: :rbs,
                                                         type_location: type_location)
        end
        type.type.required_keywords.each do |orig, param|
          # @sg-ignore Unresolved call to to_s
          name = orig ? orig.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwarg, name: name, closure: pin,
                                                         # @sg-ignore RBS generic type understanding issue
                                                         return_type: other_type_to_type(param.type),
                                                         source: :rbs, type_location: type_location)
        end
        type.type.optional_keywords.each do |orig, param|
          # @sg-ignore Unresolved call to to_s
          name = orig ? orig.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwoptarg, name: name, closure: pin,
                                                         # @sg-ignore RBS generic type understanding issue
                                                         return_type: other_type_to_type(param.type),
                                                         type_location: type_location,
                                                         source: :rbs)
        end
        if type.type.rest_keywords
          name = type.type.rest_keywords.name ? type.type.rest_keywords.name.to_s : "arg_#{arg_num += 1}"
          parameters.push Solargraph::Pin::Parameter.new(decl: :kwrestarg,
                                                         name: type.type.rest_keywords.name.to_s, closure: pin,
                                                         source: :rbs, type_location: type_location)
        end

        return_type = method_type_to_type(type, implicit_nil)
        [parameters, return_type]
      end

      # @param decl [RBS::AST::Members::AttrReader,RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @param context [Context]
      # @return [void]
      def attr_reader_to_pin decl, closure, context
        name = decl.name.to_s
        final_scope = decl.kind == :instance ? :instance : :class
        visibility = calculate_method_visibility(decl, context, closure, final_scope, name)
        pin = Solargraph::Pin::Method.new(
          name: name,
          type_location: location_decl_to_pin_location(decl.location),
          closure: closure,
          comments: decl.comment&.string,
          scope: final_scope,
          attribute: true,
          visibility: visibility,
          source: :rbs
        )
        rooted_tag = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', rooted_tag))
        logger.debug do
          "Conversions#attr_reader_to_pin(name=#{name.inspect}, visibility=#{visibility.inspect}) => #{pin.inspect}"
        end
        pins.push pin
      end

      # @param decl [RBS::AST::Members::AttrWriter, RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @param context [Context]
      # @return [void]
      def attr_writer_to_pin decl, closure, context
        final_scope = decl.kind == :instance ? :instance : :class
        name = "#{decl.name}="
        visibility = calculate_method_visibility(decl, context, closure, final_scope, name)
        type_location = location_decl_to_pin_location(decl.location)
        pin = Solargraph::Pin::Method.new(
          name: name,
          type_location: type_location,
          closure: closure,
          parameters: [],
          comments: decl.comment&.string,
          scope: final_scope,
          attribute: true,
          visibility: visibility,
          source: :rbs
        )
        pin.parameters <<
          Solargraph::Pin::Parameter.new(
            name: 'value',
            return_type: other_type_to_type(decl.type),
            source: :rbs,
            closure: pin,
            type_location: type_location
          )
        rooted_tags = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:return, '', rooted_tags))
        pins.push pin
      end

      # @param decl [RBS::AST::Members::AttrAccessor]
      # @param closure [Pin::Namespace]
      # @param context [Context]
      # @return [void]
      def attr_accessor_to_pin decl, closure, context
        attr_reader_to_pin(decl, closure, context)
        attr_writer_to_pin(decl, closure, context)
      end

      # @param decl [RBS::AST::Members::InstanceVariable]
      # @param closure [Pin::Namespace]
      # @return [void]
      def ivar_to_pin decl, closure
        pin = Solargraph::Pin::InstanceVariable.new(
          name: decl.name.to_s,
          closure: closure,
          type_location: location_decl_to_pin_location(decl.location),
          comments: decl.comment&.string,
          source: :rbs
        )
        rooted_tag = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', rooted_tag))
        pins.push pin
      end

      # @param decl [RBS::AST::Members::ClassVariable]
      # @param closure [Pin::Namespace]
      # @return [void]
      def cvar_to_pin decl, closure
        name = decl.name.to_s
        pin = Solargraph::Pin::ClassVariable.new(
          name: name,
          closure: closure,
          comments: decl.comment&.string,
          type_location: location_decl_to_pin_location(decl.location),
          source: :rbs
        )
        rooted_tag = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', rooted_tag))
        pins.push pin
      end

      # @param decl [RBS::AST::Members::ClassInstanceVariable]
      # @param closure [Pin::Namespace]
      # @return [void]
      def civar_to_pin decl, closure
        name = decl.name.to_s
        pin = Solargraph::Pin::InstanceVariable.new(
          name: name,
          closure: closure,
          comments: decl.comment&.string,
          type_location: location_decl_to_pin_location(decl.location),
          source: :rbs
        )
        rooted_tag = other_type_to_type(decl.type).rooted_tags
        pin.docstring.add_tag(YARD::Tags::Tag.new(:type, '', rooted_tag))
        pins.push pin
      end

      # @param decl [RBS::AST::Members::Include]
      # @param closure [Pin::Namespace]
      # @return [void]
      def include_to_pin decl, closure
        type = build_type(decl.name, decl.args)
        generic_values = type.all_params.map(&:rooted_tags)
        pins.push Solargraph::Pin::Reference::Include.new(
          name: type.rooted_name, # reference pins use rooted names
          type_location: location_decl_to_pin_location(decl.location),
          generic_values: generic_values,
          closure: closure,
          source: :rbs
        )
      end

      # @param decl [RBS::AST::Members::Prepend]
      # @param closure [Pin::Namespace]
      # @return [void]
      def prepend_to_pin decl, closure
        type = build_type(decl.name, decl.args)
        generic_values = type.all_params.map(&:rooted_tags)
        pins.push Solargraph::Pin::Reference::Prepend.new(
          name: type.rooted_name, # reference pins use rooted names
          type_location: location_decl_to_pin_location(decl.location),
          generic_values: generic_values,
          closure: closure,
          source: :rbs
        )
      end

      # @param decl [RBS::AST::Members::Extend]
      # @param closure [Pin::Namespace]
      # @return [void]
      def extend_to_pin decl, closure
        type = build_type(decl.name, decl.args)
        generic_values = type.all_params.map(&:rooted_tags)
        pins.push Solargraph::Pin::Reference::Extend.new(
          name: type.rooted_name, # reference pins use rooted names
          type_location: location_decl_to_pin_location(decl.location),
          generic_values: generic_values,
          closure: closure,
          source: :rbs
        )
      end

      # @param decl [RBS::AST::Members::Alias]
      # @param closure [Pin::Namespace]
      # @return [void]
      def alias_to_pin decl, closure
        final_scope = decl.singleton? ? :class : :instance
        pins.push Solargraph::Pin::MethodAlias.new(
          name: decl.new_name.to_s,
          type_location: location_decl_to_pin_location(decl.location),
          original: decl.old_name.to_s,
          closure: closure,
          scope: final_scope,
          source: :rbs
        )
      end

      # @param type [RBS::MethodType, RBS::Types::Block]
      # @return [ComplexType, ComplexType::UniqueType]
      def method_type_to_type type, implicit_nil
        tag = other_type_to_type type.type.return_type
        return ComplexType.parse("#{tag.to_s}, nil") if tag && implicit_nil
        tag
      end

      # @param type [RBS::Types::Bases::Base,Object] RBS type object.
      #   Note: Generally these extend from RBS::Types::Bases::Base,
      #   but not all.
      #
      # @return [ComplexType, ComplexType::UniqueType]
      def other_type_to_type type
        case type
        when RBS::Types::Optional
          # @sg-ignore flow based typing needs to understand case when class pattern
          ComplexType.new([other_type_to_type(type.type),
                           ComplexType::UniqueType::NIL])
        when RBS::Types::Bases::Any
          ComplexType::UNDEFINED
        when RBS::Types::Bases::Bool
          ComplexType::BOOLEAN
        when RBS::Types::Tuple
          # @sg-ignore flow based typing needs to understand case when class pattern
          tuple_types = type.types.map { |t| other_type_to_type(t) }
          ComplexType::UniqueType.new('Array', [], tuple_types, rooted: true, parameters_type: :fixed)
        when RBS::Types::Literal
          # @sg-ignore flow based typing needs to understand case when class pattern
          ComplexType.try_parse(type.literal.inspect).force_rooted
        when RBS::Types::Union
          # @sg-ignore flow based typing needs to understand case when class pattern
          ComplexType.new(type.types.map { |t| other_type_to_type(t) })
        when RBS::Types::Record
          # @todo Better record support
          ComplexType::UniqueType.new('Hash', rooted: true)
        when RBS::Types::Bases::Nil
          ComplexType::NIL
        when RBS::Types::Bases::Self
          ComplexType::SELF
        when RBS::Types::Bases::Void
          ComplexType::VOID
        when RBS::Types::Variable
          # @sg-ignore flow based typing needs to understand case when class pattern
          ComplexType.parse("generic<#{type.name}>").force_rooted
        when RBS::Types::ClassInstance # && !type.args.empty?
          # @sg-ignore flow based typing needs to understand case when class pattern
          build_type(type.name, type.args)
        when RBS::Types::Bases::Instance
          ComplexType::SELF
        when RBS::Types::Bases::Top
          # top is the most super superclass
          ComplexType::UniqueType.new('BasicObject', rooted: true)
        when RBS::Types::Bases::Bottom
          # bottom is used in contexts where nothing will ever return
          # - e.g., it could be the return type of 'exit()' or 'raise'
          #
          # @todo define a specific bottom type and use it to
          #   determine dead code
          ComplexType::UNDEFINED
        when RBS::Types::Intersection
          # @sg-ignore flow based typing needs to understand case when class pattern
          ComplexType.new(type.types.map { |member| other_type_to_type(member) })
        when RBS::Types::Proc
          ComplexType::UniqueType.new('Proc', rooted: true)
        when RBS::Types::Alias
          # type-level alias use - e.g., 'bool' in "type bool = true | false"
          # @todo ensure these get resolved after processing all aliases
          # @todo handle recursive aliases
          # @sg-ignore flow based typing needs to understand case when class pattern
          build_type(type.name, type.args)
        when RBS::Types::Interface
          # represents a mix-in module which can be considered a
          # subtype of a consumer of it
          # @sg-ignore flow based typing needs to understand case when class pattern
          build_type(type.name, type.args)
        when RBS::Types::ClassSingleton
          # e.g., singleton(String)
          # @sg-ignore flow based typing needs to understand case when class pattern
          build_type(type.name)
        else
          # RBS doesn't provide a common base class for its type AST nodes
          #
          # @sg-ignore all types should include location
          Solargraph.logger.warn "Unrecognized RBS type: #{type.class} at #{type.location}"
          ComplexType::UNDEFINED
        end
      end

      # @param decl [RBS::AST::Declarations::Class, RBS::AST::Declarations::Module]
      # @param namespace [Pin::Namespace, nil]
      # @return [void]
      def add_mixins decl, namespace
        # @param mixin [RBS::AST::Members::Include, RBS::AST::Members::Extend, RBS::AST::Members::Prepend]
        decl.each_mixin do |mixin|
          # @todo are we handling prepend correctly?
          klass = mixin.is_a?(RBS::AST::Members::Include) ? Pin::Reference::Include : Pin::Reference::Extend
          type = build_type(mixin.name, mixin.args)
          generic_values = type.all_params.map(&:rooted_tags)
          pins.push klass.new(
            name: type.rooted_name, # reference pins use rooted names
            type_location: location_decl_to_pin_location(mixin.location),
            generic_values: generic_values,
            closure: namespace,
            source: :rbs
          )
        end
      end
    end
  end
end
