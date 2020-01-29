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
    # @param api_map [ApiMap]
    # @param level [Symbol]
    def initialize filename, api_map: nil, level: :normal
      @filename = filename
      # @todo Smarter directory resolution
      @api_map = api_map || Solargraph::ApiMap.load(File.dirname(filename))
      @rules = Rules.new(level)
    end

    # @return [SourceMap]
    def source_map
      @source_map ||= api_map.source_map(filename)
    end

    # @return [Array<Problem>]
    def problems
      @problems ||= begin
        method_tag_problems
          .concat variable_type_tag_problems
          .concat call_problems
      end
    end

    class << self
      # @param filename [String]
      # @return [self]
      def load filename, level = :normal
        source = Solargraph::Source.load(filename)
        api_map = Solargraph::ApiMap.new
        api_map.map(source)
        new(filename, api_map: api_map, level: level)
      end

      # @param code [String]
      # @param filename [String, nil]
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
      # @param pin [Pin::BaseMethod]
      source_map.pins.select { |pin| pin.is_a?(Pin::BaseMethod) }.each do |pin|
        result.concat method_return_type_problems_for(pin)
        result.concat method_param_type_problems_for(pin)
      end
      result
    end

    # @param pin [Pin::BaseMethod]
    # @return [Array<Problem>]
    def method_return_type_problems_for pin
      result = []
      declared = pin.typify(api_map).self_to(pin.full_context.namespace)
      if declared.undefined?
        if pin.return_type.undefined? && rules.require_type_tags?
          result.push Problem.new(pin.location, "Missing @return tag for #{pin.path}", pin: pin)
        elsif pin.return_type.defined?
          result.push Problem.new(pin.location, "Unresolved return type #{pin.return_type} for #{pin.path}", pin: pin)
        elsif rules.must_tag_or_infer? && pin.probe(api_map).undefined?
          result.push Problem.new(pin.location, "Untyped method #{pin.path} could not be inferred")
        end
      elsif rules.validate_tags?
        unless pin.node.nil? || declared.void? || macro_pin?(pin)
          inferred = pin.probe(api_map).self_to(pin.full_context.namespace)
          if inferred.undefined?
            unless rules.ignore_all_undefined? || external?(pin)
              result.push Problem.new(pin.location, "#{pin.path} return type could not be inferred", pin: pin)
            end
          else
            unless (rules.rank > 1 ? types_match?(api_map, declared, inferred) : any_types_match?(api_map, declared, inferred))
              result.push Problem.new(pin.location, "Declared return type #{declared} does not match inferred type #{inferred} for #{pin.path}", pin: pin)
            end
          end
        end
      end
      result
    end

    def macro_pin? pin
      pin.location && source_map.source.comment_at?(pin.location.range.ending)
    end

    # @param pin [Pin::BaseMethod]
    # @return [Array<Problem>]
    def method_param_type_problems_for pin
      stack = api_map.get_method_stack(pin.namespace, pin.name, scope: pin.scope)
      params = first_param_hash(stack)
      result = []
      if rules.require_type_tags?
        pin.parameters.each do |par|
          break if par.decl == :restarg || par.decl == :kwrestarg || par.decl == :blockarg
          unless params[par.name]
            result.push Problem.new(pin.location, "Missing @param tag for #{par.name} on #{pin.path}", pin: pin)
          end
        end
      end
      params.each_pair do |name, tag|
        type = tag.qualify(api_map, pin.full_context.namespace)
        if type.undefined?
          result.push Problem.new(pin.location, "Unresolved type #{tag} for #{name} param on #{pin.path}", pin: pin)
        end
      end
      result
    end

    def ignored_pins
      @ignored_pins ||= []
    end

    # @return [Array<Problem>]
    def variable_type_tag_problems
      result = []
      all_variables.each do |pin|
        if pin.return_type.defined?
          # @todo Somwhere in here we still need to determine if the variable is defined by an external call
          declared = pin.typify(api_map)
          if declared.defined?
            if rules.validate_tags?
              inferred = pin.probe(api_map)
              if inferred.undefined?
                next if rules.ignore_all_undefined?
                # next unless internal?(pin) # @todo This might be redundant for variables
                if declared_externally?(pin)
                  ignored_pins.push pin
                else
                  result.push Problem.new(pin.location, "Variable type could not be inferred for #{pin.name}", pin: pin)
                end
              else
                unless (rules.rank > 1 ? types_match?(api_map, declared, inferred) : any_types_match?(api_map, declared, inferred))
                  result.push Problem.new(pin.location, "Declared type #{declared} does not match inferred type #{inferred} for variable #{pin.name}", pin: pin)
                end
              end
            elsif declared_externally?(pin)
              ignored_pins.push pin
            end
          elsif !pin.is_a?(Pin::Parameter)
            result.push Problem.new(pin.location, "Unresolved type #{pin.return_type} for variable #{pin.name}", pin: pin)
          end
        else
          # @todo Check if the variable is defined by an external call
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
      source_map.pins.select { |pin| pin.is_a?(Pin::BaseVariable) } +
        source_map.locals.select { |pin| pin.is_a?(Pin::LocalVariable) }
    end

    def call_problems
      return [] unless rules.validate_calls?
      result = []
      done = []
      Solargraph::Parser::NodeMethods.call_nodes_from(source_map.source.node).each do |call|
        rng = Solargraph::Range.from_node(call)
        next if done.any? { |d| d.contain?(rng.start) }
        chain = Solargraph::Parser.chain(call, filename)
        block_pin = source_map.locate_block_pin(rng.start.line, rng.start.column)
        location = Location.new(filename, Range.from_node(call))
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
            unless ignored_pins.include?(found)
              result.push Problem.new(location, "Unresolved call to #{missing.links.last.word}")
              done.push rng
            end
          end
        end
        result.concat argument_problems_for(chain, api_map, block_pin, locals, location)
      end
      result
    end

    def call_error? call
    end

    def argument_problems_for chain, api_map, block_pin, locals, location
      result = []
      base = chain
      until base.links.length == 1 && base.undefined?
        pins = base.define(api_map, block_pin, locals)
        if pins.first.is_a?(Pin::BaseMethod)
          pin = pins.first
          params = first_param_hash(pins)
          pin.parameters.each_with_index do |par, idx|
            argchain = base.links.last.arguments[idx]
            if argchain.nil? && par.decl == :arg
              result.push Problem.new(location, "Not enough arguments to #{pin.path}")
              break
            end
            if argchain
              if par.decl != :arg
                result.concat kwarg_problems_for argchain, api_map, block_pin, locals, location, pin, params, idx
                break
              else
                ptype = params[par.name]
                if ptype.nil?
                  # @todo Some level (strong, I guess) should require the param here
                else
                  argtype = argchain.infer(api_map, block_pin, locals)
                  if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
                    result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{par.name} expected #{ptype}, received #{argtype}")
                  end
                end
              end
            elsif par.rest?
              next
            elsif par.decl == :kwarg
              result.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{par.name}")
              break
            end
          end
        end
        base = base.base
      end
      result
    end

    def kwarg_problems_for argchain, api_map, block_pin, locals, location, pin, params, first
      result = []
      kwargs = convert_hash(argchain.node)
      pin.parameters[first..-1].each_with_index do |par, cur|
        idx = first + cur
        argchain = kwargs[par.name.to_sym]
        if par.decl == :kwrestarg || (par.decl == :optarg && idx == pin.parameters.length - 1 && par.asgn_code == '{}')
          result.concat kwrestarg_problems_for(api_map, block_pin, locals, location, pin, params, kwargs)
        else
          if argchain
            ptype = params[par.name]
            if ptype.nil?
              # @todo Some level (strong, I guess) should require the param here
            else
              argtype = argchain.infer(api_map, block_pin, locals)
              if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
                result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{par.name} expected #{ptype}, received #{argtype}")
              end
            end
          else
            if par.decl == :kwarg
              # @todo Problem: missing required keyword argument
              result.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{par.name}")
            end
          end
        end
      end
      result
    end

    def kwrestarg_problems_for(api_map, block_pin, locals, location, pin, params, kwargs)
      result = []
      kwargs.each_pair do |pname, argchain|
        ptype = params[pname.to_s]
        if ptype.nil?
          # Probably nothing to do here. All of these args should be optional.
        else
          argtype = argchain.infer(api_map, block_pin, locals)
          if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
            result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{pname} expected #{ptype}, received #{argtype}")
          end
        end
      end
      result
    end

    def param_hash(pin)
      tags = pin.docstring.tags(:param)
      return {} if tags.empty?
      result = {}
      tags.each do |tag|
        next if tag.types.nil? || tag.types.empty?
        result[tag.name.to_s] = Solargraph::ComplexType.try_parse(*tag.types).qualify(api_map, pin.full_context.namespace)
      end
      result
    end

    # @param [Array<Pin::Method>]
    def first_param_hash(pins)
      pins.each do |pin|
        result = param_hash(pin)
        return result unless result.empty?
      end
      {}
    end

    # @param pin [Pin::Base]
    def internal? pin
      pin.location && api_map.bundled?(pin.location.filename)
    end

    # @param pin [Pin::Base]
    def external? pin
      !internal? pin
    end

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
  end
end
