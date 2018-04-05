module Solargraph
  class Tracer
    autoload :Issue, 'solargraph/tracer/issue'

    def initialize workspace
      @workspace = workspace
      @api_map = Solargraph::ApiMap.new(workspace)
      @tracing = false
    end

    def self.load directory
      Tracer.new(Solargraph::Workspace.new(directory))
    end

    def run &block
      raise 'Tracer is already running' if trace_point.enabled?
      if block.nil?
        trace_point.enable
      else
        trace_point.enable
        block.call
        trace_point.disable
      end
    end

    def stop
      raise 'Tracer is not running' unless trace_point.enabled?
      trace_point.disable
    end

    def log *severities
      log_cache.select{|i| severities.empty? or severities.include?(i.severity)}
    end

    def clear
      log_cache.clear
      point_cache.clear
    end

    private

    def log_cache
      @log_cache ||= []
    end

    def point_cache
      @point_cache ||= []
    end

    # @return [Solargraph::Workspace]
    def workspace
      @workspace
    end

    def api_map
      @api_map
    end

    # @return [TracePoint]
    def trace_point
      @tracer ||= TracePoint.new(:return) do |tp|
        unless @tracing
          @tracing = true
          key = "#{tp.path}|#{tp.lineno}|#{tp.return_value.class.to_s}"
          unless point_cache.include?(key)
            point_cache.push key
            analyze tp
          end
          @tracing = false
        end
      end
    end

    def analyze tp
      abspath = File.absolute_path(tp.path)
      if workspace.has_file?(abspath)
        source = workspace.source(abspath)
        fragment = source.fragment_at(tp.lineno - 1, 0)
        pin = source.method_pins.select{|pin| pin.name == tp.method_id.to_s and pin.namespace == fragment.namespace and pin.scope == fragment.scope}.first
        if pin.nil?
          log_cache.push Issue.new(:warning, "Method `#{tp.method_id}` could not be found", tp.method_id, nil, tp.return_value.class.to_s, caller)
        else
          validate pin, tp.return_value, caller
        end
      end
    end

    def validate pin, value, backtrace
      return if pin.name == 'initialize' and pin.scope == :instance
      actual = value.class.to_s
      pin.resolve api_map
      if pin.return_type.nil?
        # Issue a warning for undefined return types unless the value is nil
        log_cache.push Issue.new(:warning, "`#{pin.path}` does not have a return type and returned #{actual}", pin.name, nil, actual, backtrace) unless value.nil?
      else
        expected, scope = extract_namespace_and_scope(pin.return_type)
        return if expected == actual
        return if expected == 'Boolean' and (value == true or value == false)
        sup = value.class.superclass
        while expected != sup.to_s
          sup = sup.superclass
          break if sup.nil?
        end
        return unless sup.nil?
        log_cache.push Issue.new(:error, "`#{pin.path}` should return #{pin.return_type} but returned #{actual}", pin.name, pin.return_type, actual, backtrace)
      end
    end

    # @todo DRY this method. It already exists in ApiMap.
    def extract_namespace type
      extract_namespace_and_scope(type)[0]
    end

    # @todo DRY this method. It already exists in ApiMap.
    def extract_namespace_and_scope type
      scope = :instance
      result = type.to_s.gsub(/<.*$/, '')
      if (result == 'Class' or result == 'Module') and type.include?('<')
        result = type.match(/<([a-z0-9:_]*)/i)[1]
        scope = :class
      end
      [result, scope]
    end
  end
end
