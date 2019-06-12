module Solargraph
  # A static analysis tool for validating data types.
  #
  class TypeChecker
    # A problem reported by TypeChecker.
    #
    class Problem
      # @return [Solargraph::Location]
      attr_reader :location

      # @return [String]
      attr_reader :message

      # @return [String, nil]
      attr_reader :suggestion

      # @param location [Solargraph::Location]
      # @param message [String]
      # @param suggestion [String, nil]
      def initialize location, message, suggestion = nil
        @location = location
        @message = message
        @suggestion = suggestion
      end
    end

    # @return [String]
    attr_reader :filename

    # @param filename [String]
    # @param api_map [ApiMap]
    def initialize filename, api_map: nil
      @filename = filename
      # @todo Smarter directory resolution
      @api_map = api_map || Solargraph::ApiMap.load(File.dirname(filename))
    end

    # @return [Array<Problem>]
    def return_types
      result = []
      smap = api_map.source_map(filename)
      pins = smap.pins.select { |pin| pin.is_a?(Solargraph::Pin::BaseMethod) }
      pins.each { |pin| result.concat check_return_type(pin) }
      result
    end

    # @return [Array<Problem>]
    def param_types
      result = []
      smap = api_map.source_map(filename)
      smap.locals.select { |pin| pin.is_a?(Solargraph::Pin::Parameter) }.each do |par|
        next unless par.closure.is_a?(Solargraph::Pin::Method)
        result.concat check_param_tags(par.closure)
        type = par.typify(api_map)
        if type.undefined?
          if par.return_type.undefined?
            result.push Problem.new(
              par.location, "#{par.closure.name} has undefined @param type for #{par.name}")
          else
            result.push Problem.new(par.location, "#{par.closure.name} has unresolved @param type for #{par.name}")
          end
        end
      end
      result
    end

    # @return [Array<Problem>]
    def strict_types
      result = []
      smap = api_map.source_map(filename)
      smap.pins.select { |pin| pin.is_a?(Pin::BaseMethod) }.each do |pin|
        result.concat confirm_return_type(pin)
      end
      result.concat check_send_args smap.source.node
      result
    end

    private

    # @return [ApiMap]
    attr_reader :api_map

    # @param pin [Pin::BaseMethod]
    # @return [Array<Problem>]
    def check_param_tags pin
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
      probed = pin.probe(api_map)
      if tagged.undefined?
        if pin.return_type.undefined?
          return [Problem.new(pin.location, "#{pin.name} has undefined @return type", probed.to_s)]
        else
          return [Problem.new(pin.location, "#{pin.name} has unresolved @return type #{pin.return_type}")]
        end
      end
      []
    end

    # @param pin [Solargraph::Pin::Base]
    # @return [Array<Problem>]
    def confirm_return_type pin
      tagged = pin.typify(api_map)
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
        return [Problem.new(pin.location, "@return type `#{tagged.to_s}` does not match detected type `#{probed.to_s}`", probed.to_s)]
      end
      []
    end

    def check_send_args node
      result = []
      if node.type == :send
        smap = api_map.source_map(filename)
        locals = smap.locals_at(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)))
        block = smap.locate_block_pin(node.loc.line, node.loc.column)
        chain = Solargraph::Source::NodeChainer.chain(node, filename)
        pins = chain.define(api_map, block, locals)
        if pins.empty?
          result.push Problem.new(Solargraph::Location.new(filename, Solargraph::Range.from_node(node)), "Unresolved method signature #{chain.links.map(&:word).join('.')}")
        else
          pins.each do |pin|
            # @todo Check arguments (node.children[2])
          end
        end
      end
      node.children.each do |child|
        next unless child.is_a?(Parser::AST::Node)
        result.concat check_send_args(child)
      end
      result
    end
  end
end
