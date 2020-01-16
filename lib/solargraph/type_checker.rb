# frozen_string_literal: true

module Solargraph
  # A static analysis tool for validating data types.
  #
  class TypeChecker
    autoload :Problem, 'solargraph/type_checker/problem'
    autoload :ParamDef, 'solargraph/type_checker/param_def'

    # @return [String]
    attr_reader :filename

    # @param filename [String]
    # @param api_map [ApiMap]
    def initialize filename, api_map: nil
      @filename = filename
      # @todo Smarter directory resolution
      @api_map = api_map || Solargraph::ApiMap.load(File.dirname(filename))
    end

    # Return type problems indicate that a method does not specify a type in a
    # `@return` tag or the specified type could not be resolved to a known
    # type.
    #
    # @return [Array<Problem>]
    def return_type_problems
      result = []
      smap = api_map.source_map(filename)
      pins = smap.pins.select { |pin| pin.is_a?(Solargraph::Pin::BaseMethod) }
      pins.each { |pin| result.concat check_return_type(pin) }
      result
    end

    # Param type problems indicate that a method does not specify a type in a
    # `@param` tag for one or more of its parameters, a `@param` tag is defined
    # that does not correlate with the method signature, or the specified type
    # could not be resolved to a known type.
    #
    # @return [Array<Problem>]
    def param_type_problems
      result = []
      smap = api_map.source_map(filename)
      smap.pins.select { |pin| pin.is_a?(Pin::Method) }.each do |pin|
        if pin.parameters.empty?
          pin.docstring.tags(:param).each do |tag|
            result.push Problem.new(pin.location, "#{pin.name} has unknown @param #{tag.name}", pin: pin)
          end
        end
      end
      smap.locals.select { |pin| pin.is_a?(Solargraph::Pin::Parameter) }.each do |par|
        next unless par.closure.is_a?(Solargraph::Pin::Method)
        result.concat check_param_tags(par.closure)
        type = par.typify(api_map)
        pdefs = ParamDef.from(par.closure)
        if type.undefined?
          if par.return_type.undefined? && !pdefs.any? { |pd| pd.name == par.name && [:restarg, :kwrestarg, :blockarg].include?(pd.type) }
            result.push Problem.new(par.location, "#{par.closure.name} has undefined @param type for #{par.name}")
          elsif !pdefs.any? { |pd| [:restarg, :kwrestarg, :blockarg].include?(pd.type) }
            result.push Problem.new(par.location, "#{par.closure.name} has unresolved @param type for #{par.name}")
          end
        end
      end
      result
    end

    # Strict type problems indicate that a `@return` type or a `@param` type
    # does not match the type inferred from code analysis; or that an argument
    # sent to a method does not match the type specified in the corresponding
    # `@param` tag.
    #
    # @return [Array<Problem>]
    def strict_type_problems
      result = []
      smap = api_map.source_map(filename)
      smap.pins.select { |pin| pin.is_a?(Pin::BaseMethod) }.each do |pin|
        result.concat confirm_return_type(pin)
      end
      return result if smap.source.node.nil?
      result.concat check_send_args smap.source.node
      result
    end

    private

    # @return [ApiMap]
    attr_reader :api_map

    # @param pin [Pin::BaseMethod]
    # @return [Array<Problem>]
    def check_param_tags pin
      return [] if ParamDef.from(pin).map(&:type).include?(:kwrestarg)
      result = []
      pin.docstring.tags(:param).each do |par|
        next if pin.parameter_names.include?(par.name)
        result.push Problem.new(pin.location, "#{pin.name} has unknown @param #{par.name}")
      end
      result
    end

    # @param pin [Pin::BaseMethod]
    # @return [Array<Problem>]
    def check_return_type pin
      tagged = pin.typify(api_map)
      if tagged.undefined?
        if pin.return_type.undefined?
          probed = pin.probe(api_map)
          return [Problem.new(pin.location, "#{pin.name} has undefined @return type", pin: pin, suggestion: probed.to_s)]
        else
          return [Problem.new(pin.location, "#{pin.name} has unresolved @return type #{pin.return_type}")]
        end
      end
      []
    end

    # @param pin [Solargraph::Pin::Base]
    # @return [Array<Problem>]
    def confirm_return_type pin
      tagged = pin.typify(api_map).self_to(pin.namespace)
      return [] if tagged.void? || tagged.undefined? || pin.is_a?(Pin::Attribute)
      probed = pin.probe(api_map)
      return [] if probed.undefined?
      if tagged.to_s != probed.to_s
        if probed.name == 'Array' && probed.subtypes.empty?
          return [] if tagged.name == 'Array'
        end
        if probed.name == 'Hash' && probed.value_types.empty?
          return [] if tagged.name == 'Hash'
        end
        all = true
        probed.each do |pt|
          tagged.each do |tt|
            if pt.name == tt.name && !api_map.super_and_sub?(tt.namespace, pt.namespace) && !tagged.map(&:namespace).include?(pt.namespace)
              all = false
              break
            elsif pt.name == tt.name && ['Array', 'Class', 'Module'].include?(pt.name)
              if !(tt.subtypes.any? { |ttx| pt.subtypes.any? { |ptx| api_map.super_and_sub?(ttx.to_s, ptx.to_s) } })
                all = false
                break
              end
            elsif pt.name == tt.name && pt.name == 'Hash'
              if !(tt.key_types.empty? && !pt.key_types.empty?) && !(tt.key_types.any? { |ttx| pt.key_types.any? { |ptx| api_map.super_and_sub?(ttx.to_s, ptx.to_s) } })
                if !(tt.value_types.empty? && !pt.value_types.empty?) && !(tt.value_types.any? { |ttx| pt.value_types.any? { |ptx| api_map.super_and_sub?(ttx.to_s, ptx.to_s) } })
                  all = false
                  break
                end
              end
            elsif pt.name != tt.name && !api_map.super_and_sub?(tt.to_s, pt.to_s) && !tagged.map(&:to_s).include?(pt.to_s)
              all = false
              break
            end
          end
        end
        return [] if all
        return [Problem.new(pin.location, "@return type `#{tagged.to_s}` does not match inferred type `#{probed.to_s}`", pin: pin, suggestion: probed.to_s)]
      end
      []
    end

    # @param node [Parser::AST::Node]
    # @param skip_send [Boolean]
    # @return [Array<Problem>]
    def check_send_args node, skip_send = false
      result = []
      if [:VCALL, :send].include?(node.type)
        smap = api_map.source_map(filename)
        range = Solargraph::Range.from_node(node)
        locals = smap.locals_at(Solargraph::Location.new(filename, range))
        block = smap.locate_block_pin(range.start.line, range.start.column)
        chain = Solargraph::Parser.chain(node, filename)
        pins = chain.define(api_map, block, locals).select { |pin| pin.is_a?(Pin::BaseMethod ) }
        if pins.empty?
          if !more_signature?(node)
            base = chain.base.define(api_map, block, locals).first
            if base.nil? || report_location?(base.location)
              result.push Problem.new(Solargraph::Location.new(filename, range), "Unresolved method signature #{chain.links.map(&:word).join('.')}")
            end
          end
        else
          pin = pins.first
          ptypes = ParamDef.from(pin)
          params = first_param_tags_from(pins)
          cursor = 0
          curtype = nil
          # The @param_tuple tag marks exceptional cases for handling, e.g., the Hash#[]= method.
          if pin.docstring.tag(:param_tuple)
            if node.children[2..-1].length > 2
              result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong number of arguments to #{pin.path}")
            else
              base = chain.base.infer(api_map, block, locals)
              # @todo Don't just use the first key/value type
              k = base.key_types.first || ComplexType.parse('Object')
              v = base.value_types.first || ComplexType.parse('Object')
              tuple = [
                ParamDef.new('key', k),
                ParamDef.new('value', v)
              ]
              node.children[2..-1].each_with_index do |arg, index|
                chain = Solargraph::Source::NodeChainer.chain(arg, filename)
                argtype = chain.infer(api_map, block, locals)
                partype = tuple[index].type
                if argtype.tag != partype.tag && !api_map.super_and_sub?(partype.tag.to_s, argtype.tag.to_s)
                  result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong parameter type for #{pin.path}: #{tuple[index].name} expected #{partype.tag}, received #{argtype.tag}")
                end
              end
            end
            return result
          end
          node.children[2..-1].each_with_index do |arg, index|
            if pin.is_a?(Pin::Attribute)
              curtype = ParamDef.new('value', :arg)
            else
              curtype = ptypes[cursor] if curtype.nil? || curtype == :arg
            end
            if curtype.nil?
              if pin.parameters[index].nil?
                if params.values[index]
                  # Allow for methods that have named parameters but no
                  # arguments in their definitions. This is common in the Ruby
                  # core, e.g., the Hash#[]= method.
                  chain = Solargraph::Source::NodeChainer.chain(arg, filename)
                  argtype = chain.infer(api_map, block, locals)
                  partype = params.values[index]
                  if argtype.tag != partype.tag && !api_map.super_and_sub?(partype.tag.to_s, argtype.tag.to_s)
                    result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong parameter type for #{pin.path}: #{params.keys[index]} expected #{partype.tag}, received #{argtype.tag}")
                  end
                else
                  result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Not enough arguments sent to #{pin.path}")
                  break
                end
              end
            else
              # @todo This should also detect when the last parameter is a hash
              if curtype.type == :kwrestarg
                if arg.type != :hash
                  result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong parameter type for #{pin.path}: expected hash or keyword")
                else
                  result.concat check_hash_params arg, params
                end
                # @todo Break here? Not sure about that
                break
              end
              break if curtype.type == :restarg
              if arg.is_a?(Parser::AST::Node) && arg.type == :hash
                arg.children.each do |pair|
                  sym = pair.children[0].children[0].to_s
                  partype = params[sym]
                  if partype
                    chain = Solargraph::Source::NodeChainer.chain(pair.children[1], filename)
                    argtype = chain.infer(api_map, block, locals)
                    if argtype.tag != partype.tag && !api_map.super_and_sub?(partype.tag.to_s, argtype.tag.to_s)
                      result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong parameter type for #{pin.path}: #{pin.parameter_names[index]} expected #{partype.tag}, received #{argtype.tag}")
                    end
                  end
                end
              elsif arg.is_a?(Parser::AST::Node) && arg.type == :splat
                result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Can't handle splat in #{pin.parameter_names[index]} #{pin.path}")
                break if curtype != :arg && ptypes.map(&:type).include?(:restarg)
              else
                if pin.is_a?(Pin::Attribute)
                  partype = pin.return_type
                else
                  partype = params[pin.parameter_names[index]]
                end
                if partype
                  arg = chain.links.last.arguments[index]
                  if arg.nil?
                    result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong number of arguments to #{pin.path}")
                  else
                    argtype = arg.infer(api_map, block, locals)
                    if !arg_to_duck(argtype, partype)
                      match = false
                      partype.each do |pt|
                        if argtype.tag == pt.tag || api_map.super_and_sub?(pt.tag.to_s, argtype.tag.to_s)
                          match = true
                          break
                        end
                      end
                      unless match
                        result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Wrong parameter type for #{pin.path}: #{pin.parameter_names[index]} expected [#{partype}], received [#{argtype.tag}]")
                      end
                    end
                  end
                end
              end
            end
            cursor += 1 if curtype == :arg
          end
        end
      end
      node.children.each do |child|
        # next unless child.is_a?(Parser::AST::Node)
        next unless Parser.is_ast_node?(child)
        next if [:VCALL, :SEND, :send].include?(child.type) && skip_send
        result.concat check_send_args(child)
      end
      result
    end

    def check_hash_params arg, params
      result = []
      keys = arg.children.map do |child|
        child.children[0].children[0].to_s
      end
      keys.each do |key|
        param = params[key]
        if param
          # @todo typecheck
        else
          # @todo This error might not be valid. If there's a splat in the
          #   method parameters, should the type checker let it pass?
          result.push Problem.new(nil, "Keyword argument #{key} does not have a @param tag")
        end
      end
      result
    end

    def arg_to_duck arg, par
      return false unless par.duck_type?
      meths = api_map.get_complex_type_methods(arg).map(&:name)
      par.each do |quack|
        return false unless meths.include?(quack.to_s[1..-1])
      end
      true
    end

    # @param pin [Pin::Base]
    # @return [Hash]
    def param_tags_from pin
      # @todo Look for see references
      #   and dig through all the pins
      return {} if pin.nil?
      tags = pin.docstring.tags(:param)
      result = {}
      tags.each do |tag|
        result[tag.name] = ComplexType::UNDEFINED
        result[tag.name] = ComplexType.try_parse(*tag.types).qualify(api_map, pin.context.namespace)
      end
      result
    end

    def first_param_tags_from pins
      pins.each do |pin|
        result = param_tags_from(pin)
        return result unless result.empty?
      end
      {}
    end

    # @param location [Location, nil]
    def report_location? location
      return false if location.nil?
      filename == location.filename || api_map.bundled?(location.filename)
    end

    def more_signature? node
      node.children.any? do |child|
        Parser.is_ast_node?(child) && (
          child.type == :send || (child.type == :block && more_signature?(child))
        )
      end
    end

    class << self
      # @param filename [String]
      # @return [self]
      def load filename
        source = Solargraph::Source.load(filename)
        api_map = Solargraph::ApiMap.new
        api_map.map(source)
        new(filename, api_map: api_map)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @return [self]
      def load_string code, filename = nil
        source = Solargraph::Source.load_string(code, filename)
        api_map = Solargraph::ApiMap.new
        api_map.map(source)
        new(filename, api_map: api_map)
      end
    end
  end
end
