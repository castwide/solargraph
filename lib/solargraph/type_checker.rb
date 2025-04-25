# frozen_string_literal: true

module Solargraph
  # A static analysis tool for validating data types.
  #
  class TypeChecker
    autoload :Problem,  'solargraph/type_checker/problem'
    autoload :ParamDef, 'solargraph/type_checker/param_def'
    autoload :Rules,    'solargraph/type_checker/rules'
    autoload :Checks,   'solargraph/type_checker/checks'

    include Checks
    include Parser::NodeMethods

    # @return [String]
    attr_reader :filename

    # @return [Rules]
    attr_reader :rules

    # @return [ApiMap]
    attr_reader :api_map

    # @param filename [String]
    # @param api_map [ApiMap, nil]
    # @param level [Symbol]
    def initialize filename, api_map: nil, level: :normal
      @filename = filename
      # @todo Smarter directory resolution
      @api_map = api_map || Solargraph::ApiMap.load(File.dirname(filename))
      @rules = Rules.new(level)
      @marked_ranges = []
    end

    # @return [SourceMap]
    def source_map
      @source_map ||= api_map.source_map(filename)
    end

    # @return [Array<Problem>]
    def problems
      @problems ||= begin
        without_ignored(
          method_tag_problems
            .concat variable_type_tag_problems
            .concat const_problems
            .concat call_problems
        )
      end
    end

    class << self
      # @param filename [String]
      # @param level [Symbol]
      # @return [self]
      def load filename, level = :normal
        source = Solargraph::Source.load(filename)
        api_map = Solargraph::ApiMap.new
        api_map.map(source)
        new(filename, api_map: api_map, level: level)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @param level [Symbol]
      # @return [self]
      def load_string code, filename = nil, level = :normal
        source = Solargraph::Source.load_string(code, filename)
        api_map = Solargraph::ApiMap.new
        api_map.map(source)
        new(filename, api_map: api_map, level: level)
      end
    end

    private

    # @return [Array<Problem>]
    def method_tag_problems
      result = []
      # @param pin [Pin::Method]
      source_map.pins_by_class(Pin::Method).each do |pin|
        result.concat method_return_type_problems_for(pin)
        result.concat method_param_type_problems_for(pin)
      end
      result
    end

    # @param pin [Pin::Method]
    # @return [Array<Problem>]
    def method_return_type_problems_for pin
      return [] if pin.is_a?(Pin::MethodAlias)
      result = []
      declared = pin.typify(api_map).self_to_type(pin.full_context).qualify(api_map, pin.full_context.tag)
      if declared.undefined?
        if pin.return_type.undefined? && rules.require_type_tags?
          if pin.attribute?
            inferred = pin.probe(api_map).self_to_type(pin.full_context)
            result.push Problem.new(pin.location, "Missing @return tag for #{pin.path}", pin: pin) unless inferred.defined?
          else
            result.push Problem.new(pin.location, "Missing @return tag for #{pin.path}", pin: pin)
          end
        elsif pin.return_type.defined? && !resolved_constant?(pin)
          result.push Problem.new(pin.location, "Unresolved return type #{pin.return_type} for #{pin.path}", pin: pin)
        elsif rules.must_tag_or_infer? && pin.probe(api_map).undefined?
          result.push Problem.new(pin.location, "Untyped method #{pin.path} could not be inferred")
        end
      elsif rules.validate_tags?
        unless pin.node.nil? || declared.void? || virtual_pin?(pin) || abstract?(pin)
          inferred = pin.probe(api_map).self_to_type(pin.full_context)
          if inferred.undefined?
            unless rules.ignore_all_undefined? || external?(pin)
              result.push Problem.new(pin.location, "#{pin.path} return type could not be inferred", pin: pin)
            end
          else
            unless (rules.require_all_return_types_match_inferred? ? all_types_match?(api_map, inferred, declared) : any_types_match?(api_map, declared, inferred))
              result.push Problem.new(pin.location, "Declared return type #{declared.rooted_tags} does not match inferred type #{inferred.rooted_tags} for #{pin.path}", pin: pin)
            end
          end
        end
      end
      result
    end

    # @todo This is not optimal. A better solution would probably be to mix
    #   namespace alias into types at the ApiMap level.
    #
    # @param pin [Pin::Base]
    # @return [Boolean]
    def resolved_constant? pin
      return true if pin.typify(api_map).defined?
      constant_pins = api_map.get_constants('', *pin.closure.gates)
               .select { |p| p.name == pin.return_type.namespace }
      return true if constant_pins.find { |p| p.typify(api_map).defined? }
      # will need to probe when a constant name is assigned to a
      # class/module (alias)
      return true if constant_pins.find { |p| p.probe(api_map).defined? }
      false
    end

    # @param pin [Pin::Base]
    def virtual_pin? pin
      pin.location && source_map.source.comment_at?(pin.location.range.ending)
    end

    # @param pin [Pin::Method]
    # @return [Array<Problem>]
    def method_param_type_problems_for pin
      stack = api_map.get_method_stack(pin.namespace, pin.name, scope: pin.scope)
      params = first_param_hash(stack)
      result = []
      if rules.require_type_tags?
        pin.signatures.each do |sig|
          sig.parameters.each do |par|
            break if par.decl == :restarg || par.decl == :kwrestarg || par.decl == :blockarg
            unless params[par.name]
              if pin.attribute?
                inferred = pin.probe(api_map).self_to_type(pin.full_context)
                if inferred.undefined?
                  result.push Problem.new(pin.location, "Missing @param tag for #{par.name} on #{pin.path}", pin: pin)
                end
              else
                result.push Problem.new(pin.location, "Missing @param tag for #{par.name} on #{pin.path}", pin: pin)
              end
            end
          end
        end
      end
      # @todo Should be able to probe type of name and data here
      # @param name [String]
      # @param data [Hash{Symbol => BasicObject}]
      params.each_pair do |name, data|
        # @type [ComplexType]
        type = data[:qualified]
        if type.undefined?
          result.push Problem.new(pin.location, "Unresolved type #{data[:tagged]} for #{name} param on #{pin.path}", pin: pin)
        end
      end
      result
    end

    # @return [Array<Pin::Base>]
    def ignored_pins
      @ignored_pins ||= []
    end

    # @return [Array<Problem>]
    def variable_type_tag_problems
      result = []
      all_variables.each do |pin|
        if pin.return_type.defined?
          declared = pin.typify(api_map)
          next if declared.duck_type?
          if declared.defined?
            if rules.validate_tags?
              inferred = pin.probe(api_map)
              if inferred.undefined?
                next if rules.ignore_all_undefined?
                if declared_externally?(pin)
                  ignored_pins.push pin
                else
                  result.push Problem.new(pin.location, "Variable type could not be inferred for #{pin.name}", pin: pin)
                end
              else
                unless any_types_match?(api_map, declared, inferred)
                  result.push Problem.new(pin.location, "Declared type #{declared} does not match inferred type #{inferred} for variable #{pin.name}", pin: pin)
                end
              end
            elsif declared_externally?(pin)
              ignored_pins.push pin
            end
          elsif !pin.is_a?(Pin::Parameter) && !resolved_constant?(pin)
            result.push Problem.new(pin.location, "Unresolved type #{pin.return_type} for variable #{pin.name}", pin: pin)
          end
        else
          inferred = pin.probe(api_map)
          if inferred.undefined? && declared_externally?(pin)
            ignored_pins.push pin
          end
        end
      end
      result
    end

    # @return [Array<Pin::BaseVariable>]
    def all_variables
      source_map.pins_by_class(Pin::BaseVariable) + source_map.locals.select { |pin| pin.is_a?(Pin::LocalVariable) }
    end

    # @return [Array<Problem>]
    def const_problems
      return [] unless rules.validate_consts?
      result = []
      Solargraph::Parser::NodeMethods.const_nodes_from(source_map.source.node).each do |const|
        rng = Solargraph::Range.from_node(const)
        chain = Solargraph::Parser.chain(const, filename)
        block_pin = source_map.locate_block_pin(rng.start.line, rng.start.column)
        location = Location.new(filename, rng)
        locals = source_map.locals_at(location)
        pins = chain.define(api_map, block_pin, locals)
        if pins.empty?
          result.push Problem.new(location, "Unresolved constant #{Solargraph::Parser::NodeMethods.unpack_name(const)}")
          @marked_ranges.push location.range
        end
      end
      result
    end

    # @return [Array<Problem>]
    def call_problems
      result = []
      Solargraph::Parser::NodeMethods.call_nodes_from(source_map.source.node).each do |call|
        rng = Solargraph::Range.from_node(call)
        next if @marked_ranges.any? { |d| d.contain?(rng.start) }
        chain = Solargraph::Parser.chain(call, filename)
        block_pin = source_map.locate_block_pin(rng.start.line, rng.start.column)
        location = Location.new(filename, rng)
        locals = source_map.locals_at(location)
        type = chain.infer(api_map, block_pin, locals)
        if type.undefined? && !rules.ignore_all_undefined?
          base = chain
          missing = chain
          found = nil
          closest = ComplexType::UNDEFINED
          until base.links.first.undefined?
            found = base.define(api_map, block_pin, locals).first
            break if found
            missing = base
            base = base.base
          end
          closest = found.typify(api_map) if found
          # @todo remove the internal_or_core? check at a higher-than-strict level
          if !found || found.is_a?(Pin::BaseVariable) || (closest.defined? && internal_or_core?(found))
            unless closest.generic? || ignored_pins.include?(found)
              result.push Problem.new(location, "Unresolved call to #{missing.links.last.word}")
              @marked_ranges.push rng
            end
          end
        end
        result.concat argument_problems_for(chain, api_map, block_pin, locals, location)
      end
      result
    end

    # @param chain [Solargraph::Source::Chain]
    # @param api_map [Solargraph::ApiMap]
    # @param block_pin [Solargraph::Pin::Base]
    # @param locals [Array<Solargraph::Pin::Base>]
    # @param location [Solargraph::Location]
    # @return [Array<Problem>]
    def argument_problems_for chain, api_map, block_pin, locals, location
      result = []
      base = chain
      until base.links.length == 1 && base.undefined?
        last_base_link = base.links.last
        break unless last_base_link.is_a?(Solargraph::Source::Chain::Call)

        arguments = last_base_link.arguments

        pins = base.define(api_map, block_pin, locals)

        first_pin = pins.first
        if first_pin.is_a?(Pin::DelegatedMethod) && !first_pin.resolvable?(api_map)
          # Do nothing, as we can't find the actual method implementation
        elsif first_pin.is_a?(Pin::Method)
          # @type [Pin::Method]
          pin = first_pin
          ap = if base.links.last.is_a?(Solargraph::Source::Chain::ZSuper)
            arity_problems_for(pin, fake_args_for(block_pin), location)
          elsif pin.path == 'Class#new'
            fqns = if base.links.one?
              block_pin.namespace
            else
              base.base.infer(api_map, block_pin, locals).namespace
            end
            init = api_map.get_method_stack(fqns, 'initialize').first
            init ? arity_problems_for(init, arguments, location) : []
          else
            arity_problems_for(pin, arguments, location)
          end
          unless ap.empty?
            result.concat ap
            break
          end
          break if !rules.validate_calls? || base.links.first.is_a?(Solargraph::Source::Chain::ZSuper)

          params = first_param_hash(pins)

          all_errors = []
          pin.signatures.sort { |sig| sig.parameters.length }.each do |sig|
            errors = []
            sig.parameters.each_with_index do |par, idx|
              # @todo add logic mapping up restarg parameters with
              #   arguments (including restarg arguments).  Use tuples
              #   when possible, and when not, ensure provably
              #   incorrect situations are detected.
              break if par.decl == :restarg  # bail out pending better arg processing
              argchain = arguments[idx]
              if argchain.nil?
                if par.decl == :arg
                  final_arg = arguments.last
                  if final_arg && final_arg.node.type == :splat
                    argchain = final_arg
                    next # don't try to apply the type of the splat - unlikely to be specific enough
                  else
                    errors.push Problem.new(location, "Not enough arguments to #{pin.path}")
                    next
                  end
                else
                  final_arg = arguments.last
                  argchain = final_arg if final_arg && [:kwsplat, :hash].include?(final_arg.node.type)
                end
              end
              if argchain
                if par.decl != :arg
                  errors.concat kwarg_problems_for sig, argchain, api_map, block_pin, locals, location, pin, params, idx
                  next
                else
                  if argchain.node.type == :splat && argchain == arguments.last
                    final_arg = argchain
                  end
                  if (final_arg && final_arg.node.type == :splat)
                    # The final argument given has been seen and was a
                    # splat, which doesn't give us useful types or
                    # arities against positional parameters, so let's
                    # continue on in case there are any required
                    # kwargs we should warn about
                    next
                  end

                  if argchain.node.type == :splat && par != sig.parameters.last
                    # we have been given a splat and there are more
                    # arguments to come.

                    # @todo Improve this so that we can skip past the
                    #   rest of the positional parameters here but still
                    #   process the kwargs
                    break
                  end
                  ptype = params.key?(par.name) ? params[par.name][:qualified] : ComplexType::UNDEFINED
                  ptype = ptype.self_to_type(par.context)
                  if ptype.nil?
                    # @todo Some level (strong, I guess) should require the param here
                  else
                    argtype = argchain.infer(api_map, block_pin, locals)
                    if argtype.defined? && ptype.defined? && !any_types_match?(api_map, ptype, argtype)
                      errors.push Problem.new(location, "Wrong argument type for #{pin.path}: #{par.name} expected #{ptype}, received #{argtype}")
                      next
                    end
                  end
                end
              elsif par.decl == :kwarg
                errors.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{par.name}")
                next
              end
            end
            if errors.empty?
              all_errors.clear
              break
            end
            all_errors.concat errors
          end
          result.concat all_errors
        end
        base = base.base
      end
      result
    end

    # @param sig [Pin::Signature]
    # @param argchain [Source::Chain]
    # @param api_map [ApiMap]
    # @param block_pin [Pin::Block]
    # @param locals [Array<Pin::LocalVariable>]
    # @param location [Location]
    # @param pin [Pin::Method]
    # @param params [Hash{String => Hash{Symbol => String, Solargraph::ComplexType}}]
    # @param idx [Integer]
    #
    # @return [Array<Problem>]
    def kwarg_problems_for sig, argchain, api_map, block_pin, locals, location, pin, params, idx
      result = []
      kwargs = convert_hash(argchain.node)
      par = sig.parameters[idx]
      argchain = kwargs[par.name.to_sym]
      if par.decl == :kwrestarg || (par.decl == :optarg && idx == pin.parameters.length - 1 && par.asgn_code == '{}')
        result.concat kwrestarg_problems_for(api_map, block_pin, locals, location, pin, params, kwargs)
      else
        if argchain
          data = params[par.name]
          if data.nil?
            # @todo Some level (strong, I guess) should require the param here
          else
            ptype = data[:qualified]
            unless ptype.undefined?
              argtype = argchain.infer(api_map, block_pin, locals)
              if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
                result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{par.name} expected #{ptype}, received #{argtype}")
              end
            end
          end
        elsif par.decl == :kwarg
          result.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{par.name}")
        end
      end
      result
    end

    # @param api_map [ApiMap]
    # @param block_pin [Pin::Block]
    # @param locals [Array<Pin::LocalVariable>]
    # @param location [Location]
    # @param pin [Pin::Method]
    # @param params [Hash{String => [nil, Hash]}]
    # @param kwargs [Hash{Symbol => Source::Chain}]
    # @return [Array<Problem>]
    def kwrestarg_problems_for(api_map, block_pin, locals, location, pin, params, kwargs)
      result = []
      kwargs.each_pair do |pname, argchain|
        next unless params.key?(pname.to_s)
        ptype = params[pname.to_s][:qualified]
        argtype = argchain.infer(api_map, block_pin, locals)
        if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
          result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{pname} expected #{ptype}, received #{argtype}")
        end
      end
      result
    end

    # @param pin [Pin::Method]
    # @return [Hash{String => Hash{Symbol => String, ComplexType}}]
    def param_hash(pin)
      tags = pin.docstring.tags(:param)
      return {} if tags.empty?
      # @type [Hash{String => Hash{Symbol => String, ComplexType}}]
      result = {}
      tags.each do |tag|
        next if tag.types.nil? || tag.types.empty?
        result[tag.name.to_s] = {
          tagged: tag.types.join(', '),
          qualified: Solargraph::ComplexType.try_parse(*tag.types).qualify(api_map, pin.full_context.namespace)
        }
      end
      result
    end

    # @param pins [Array<Pin::Method>]
    # @return [Hash{String => Hash{Symbol => String, ComplexType}}]
    def first_param_hash(pins)
      pins.each do |pin|
        result = param_hash(pin)
        return result unless result.empty?
      end
      {}
    end

    # @param pin [Pin::Base]
    def internal? pin
      return false if pin.nil?
      pin.location && api_map.bundled?(pin.location.filename)
    end

    # True if the pin is either internal (part of the workspace) or from the core/stdlib
    # @param pin [Pin::Base]
    def internal_or_core? pin
      # @todo RBS pins are not necessarily core/stdlib pins
      internal?(pin) || pin.source == :rbs
    end

    # @param pin [Pin::Base]
    def external? pin
      !internal? pin
    end

    # @param pin [Pin::Base]
    def declared_externally? pin
      return true if pin.assignment.nil?
      chain = Solargraph::Parser.chain(pin.assignment, filename)
      rng = Solargraph::Range.from_node(pin.assignment)
      block_pin = source_map.locate_block_pin(rng.start.line, rng.start.column)
      location = Location.new(filename, Range.from_node(pin.assignment))
      locals = source_map.locals_at(location)
      type = chain.infer(api_map, block_pin, locals)
      if type.undefined? && !rules.ignore_all_undefined?
        base = chain
        missing = chain
        found = nil
        closest = ComplexType::UNDEFINED
        until base.links.first.undefined?
          found = base.define(api_map, block_pin, locals).first
          break if found
          missing = base
          base = base.base
        end
        closest = found.typify(api_map) if found
        if !found || closest.defined? || internal?(found)
          return false
        end
      end
      true
    end

    # @param pin [Pin::Method]
    # @param arguments [Array<Source::Chain>]
    # @param location [Location]
    # @return [Array<Problem>]
    def arity_problems_for pin, arguments, location
      results = pin.signatures.map do |sig|
        r = parameterized_arity_problems_for(pin, sig.parameters, arguments, location)
        return [] if r.empty?
        r
      end
      results.first
    end

    # @param pin [Pin::Method]
    # @param parameters [Array<Pin::Parameter>]
    # @param arguments [Array<Source::Chain>]
    # @param location [Location]
    # @return [Array<Problem>]
    def parameterized_arity_problems_for(pin, parameters, arguments, location)
      return [] unless pin.explicit?
      return [] if parameters.empty? && arguments.empty?
      return [] if pin.anon_splat?
      unchecked = arguments.clone
      add_params = 0
      if unchecked.empty? && parameters.any? { |param| param.decl == :kwarg }
        return [Problem.new(location, "Missing keyword arguments to #{pin.path}")]
      end
      settled_kwargs = 0
      unless unchecked.empty?
        if any_splatted_call?(unchecked.map(&:node))
          settled_kwargs = parameters.count(&:keyword?)
        else
          kwargs = convert_hash(unchecked.last.node)
          if parameters.any? { |param| [:kwarg, :kwoptarg].include?(param.decl) || param.kwrestarg? }
            if kwargs.empty?
              add_params += 1
            else
              unchecked.pop
              parameters.each do |param|
                next unless param.keyword?
                if kwargs.key?(param.name.to_sym)
                  kwargs.delete param.name.to_sym
                  settled_kwargs += 1
                elsif param.decl == :kwarg
                  return [] if arguments.last.links.last.is_a?(Solargraph::Source::Chain::Hash) && arguments.last.links.last.splatted?
                  return [Problem.new(location, "Missing keyword argument #{param.name} to #{pin.path}")]
                end
              end
              kwargs.clear if parameters.any?(&:kwrestarg?)
              unless kwargs.empty?
                return [Problem.new(location, "Unrecognized keyword argument #{kwargs.keys.first} to #{pin.path}")]
              end
            end
          end
        end
      end
      req = required_param_count(parameters)
      if req + add_params < unchecked.length
        return [] if parameters.any?(&:rest?)
        opt = optional_param_count(parameters)
        return [] if unchecked.length <= req + opt
        if req + add_params + 1 == unchecked.length && any_splatted_call?(unchecked.map(&:node)) && (parameters.map(&:decl) & [:kwarg, :kwoptarg, :kwrestarg]).any?
          return []
        end
        return [] if arguments.length - req == parameters.select { |p| [:optarg, :kwoptarg].include?(p.decl) }.length
        return [Problem.new(location, "Too many arguments to #{pin.path}")]
      elsif unchecked.length < req - settled_kwargs && (arguments.empty? || (!arguments.last.splat? && !arguments.last.links.last.is_a?(Solargraph::Source::Chain::Hash)))
        # HACK: Kernel#raise signature is incorrect in Ruby 2.7 core docs.
        # See https://github.com/castwide/solargraph/issues/418
        unless arguments.empty? && pin.path == 'Kernel#raise'
          return [Problem.new(location, "Not enough arguments to #{pin.path}")]
        end
      end
      []
    end

    # @param parameters [Enumerable<Pin::Parameter>]
    # @todo need to use generic types in method to choose correct
    #   signature and generate Integer as return type
    # @sg-ignore
    # @return [Integer]
    def required_param_count(parameters)
      parameters.sum { |param| %i[arg kwarg].include?(param.decl) ? 1 : 0 }
    end

    # @param parameters [Enumerable<Pin::Parameter>]
    # @param pin [Pin::Method]
    # @return [Integer]
    def optional_param_count(parameters)
      parameters.select { |p| p.decl == :optarg }.length
    end

    # @param pin [Pin::Method]
    def abstract? pin
      pin.docstring.has_tag?('abstract') ||
        (pin.closure && pin.closure.docstring.has_tag?('abstract'))
    end

    # @param pin [Pin::Base]
    # @return [Array<Source::Chain>]
    def fake_args_for(pin)
      args = []
      with_opts = false
      with_block = false
      pin.parameters.each do |pin|
        if [:kwarg, :kwoptarg, :kwrestarg].include?(pin.decl)
          with_opts = true
        elsif pin.decl == :block
          with_block = true
        elsif pin.decl == :restarg
          args.push Solargraph::Source::Chain.new([Solargraph::Source::Chain::Variable.new(pin.name)], nil, true)
        else
          args.push Solargraph::Source::Chain.new([Solargraph::Source::Chain::Variable.new(pin.name)])
        end
      end
      args.push Solargraph::Parser.chain_string('{}') if with_opts
      args.push Solargraph::Parser.chain_string('&') if with_block
      args
    end

    # @param problems [Array<Problem>]
    # @return [Array<Problem>]
    def without_ignored problems
      problems.reject do |problem|
        node = source_map.source.node_at(problem.location.range.start.line, problem.location.range.start.column)
        node && source_map.source.comments_for(node)&.include?('@sg-ignore')
      end
    end
  end
end
