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
        unless declared.void? || pin.is_a?(Pin::Attribute) || macro_pin?(pin)
          inferred = pin.probe(api_map).self_to(pin.full_context.namespace)
          if inferred.undefined?
            unless rules.ignore_all_undefined? || external?(pin)
              result.push Problem.new(pin.location, "#{pin.path} return type could not be inferred", pin: pin)
            end
          else
            unless types_match? api_map, declared, inferred
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
      params = param_hash(pin)
      result = []
      if rules.require_type_tags?
        pin.parameter_names.each_with_index do |name, index|
          full = pin.parameters[index]
          break if full.start_with?('*') || full.start_with?('&')
          unless params[name]
            result.push Problem.new(pin.location, "Missing @param tag for #{name} on #{pin.path}", pin: pin)
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

    # @return [Array<Problem>]
    def variable_type_tag_problems
      result = []
      all_variables.each do |pin|
        if pin.return_type.defined?
          declared = pin.typify(api_map)
          if declared.defined?
            if rules.validate_tags?
              inferred = pin.probe(api_map)
              if inferred.undefined?
                next if rules.ignore_all_undefined?
                next unless internal?(pin) # @todo This might be redundant for variables
                result.push Problem.new(pin.location, "Variable type could not be inferred for #{pin.name}", pin: pin)
              else
                unless types_match? api_map, declared, inferred
                  result.push Problem.new(pin.location, "Declared type #{declared} does not match inferred type #{inferred} for variable #{pin.name}", pin: pin)
                end
              end
            end
          elsif !pin.is_a?(Pin::Parameter)
            result.push Problem.new(pin.location, "Unresolved type #{pin.return_type} for variable #{pin.name}", pin: pin)
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
      result = []
      Solargraph::Source::NodeMethods.call_nodes_from(source_map.source.node).each do |call|
        chain = Solargraph::Source::NodeChainer.chain(call, filename)
        block_pin = source_map.locate_block_pin(call.loc.expression.line, call.loc.expression.column)
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
            result.push Problem.new(location, "Unresolved call to #{missing.links.last.word}")
          end
        end
        result.concat argument_problems_for(chain, api_map, block_pin, locals, location)
      end
      result
    end

    def argument_problems_for chain, api_map, block_pin, locals, location
      result = []
      base = chain
      until base.links.length == 1 && base.undefined?
        pins = base.define(api_map, block_pin, locals)
        if pins.first.is_a?(Pin::Method)
          pin = pins.first
          params = first_param_hash(pins)
          pin.parameter_names.each_with_index do |name, index|
            full = pin.parameters[index]
            argchain = base.links.last.arguments[index]
            if argchain
              if full.start_with?("#{name}:") || full.start_with?('**') || (full.end_with?('{}') && index == pin.parameter_names.length - 1)
                result.concat kwarg_problems_for argchain, api_map, block_pin, locals, location, pin, params, index
                break
              else
                ptype = params[name]
                if ptype.nil?
                  # @todo Some level (strong, I guess) should require the param here
                else
                  argtype = argchain.infer(api_map, block_pin, locals)
                  if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
                    result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{name} expected #{ptype}, received #{argtype}")
                  end
                end
              end
            elsif full.start_with?('*') || full.start_with?('&') || full.include?('=')
              next
            else
              if full.end_with?(":")
                result.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{name}")
              elsif !full.start_with?("#{name}:")
                result.push Problem.new(location, "Not enough arguments to #{pin.path} (missing #{name})")
              end
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
      kwargs = convert_hash_node(argchain.node)
      pin.parameter_names[first..-1].each_with_index do |pname, index|
        full = pin.parameters[index]
        argchain = kwargs[pname.to_sym]
        if full.start_with?('**') || full.end_with?('{}')
          result.concat kwrestarg_problems_for(api_map, block_pin, locals, location, pin, params, kwargs)
        else
          if argchain
            ptype = params[pname]
            if ptype.nil?
              # @todo Some level (strong, I guess) should require the param here
            else
              argtype = argchain.infer(api_map, block_pin, locals)
              if argtype.defined? && ptype && !any_types_match?(api_map, ptype, argtype)
                result.push Problem.new(location, "Wrong argument type for #{pin.path}: #{pname} expected #{ptype}, received #{argtype}")
              end
            end
          else
            if full.end_with?(':')
              # @todo Problem: missing required keyword argument
              result.push Problem.new(location, "Call to #{pin.path} is missing keyword argument #{pname}")
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

    def convert_hash_node node
      return {} unless node.type == :hash
      result = {}
      node.children.each do |pair|
        result[pair.children[0].children[0]] = Solargraph::Source::NodeChainer.chain(pair.children[1])
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
  end
end
