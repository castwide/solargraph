module Solargraph
  class Tracer
    autoload :Issue, 'solargraph/tracer/issue'

    def initialize workspace
      @workspace = workspace
      @api_map = Solargraph::ApiMap.new(workspace)
      @tracing = false
    end

    # @return [Tracer]
    def self.load directory
      Tracer.new(Solargraph::Workspace.new(directory))
    end

    def run
      raise 'Tracer is already running' if trace_point.enabled?
      trace_point.enable
      return unless block_given?
      yield
      trace_point.disable
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

    def call_point_cache
      @call_point_cache ||= []
    end

    def return_point_cache
      @return_point_cache ||= []
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
      @tracer ||= TracePoint.new(:call, :return) do |tp|
        begin
          next if @tracing
          @tracing = true
          if tracing_file?(tp.path)
            if tp.event == :call
              analyze_call tp, caller
            elsif tp.event == :return
              analyze_return tp, caller
            end
          end
          @tracing = false
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace[0]
        end
      end
    end

    def analyze_call tp, backtrace
      STDERR.puts "Analyzing a call. Problems are certain"
      klasses = []
      tp.binding.local_variables.each do |l|
        klasses.push tp.binding.local_variable_get(l).class.to_s
      end
      key = "#{tp.path}|#{tp.lineno}|#{klasses.join(',')}"
      return if call_point_cache.include?(key)
      call_point_cache.push key
      pin = get_method_pin(tp.path, tp.lineno, tp.method_id)
      if pin.nil?
        log_cache.push Issue.new(:warning, "Method `#{tp.method_id}` could not be found", tp.method_id, nil, backtrace)
      else
        validate_call pin, tp, backtrace
      end
    end

    def analyze_return tp, backtrace
      key = "#{tp.path}|#{tp.lineno}|#{tp.return_value.class.to_s}"
      return if return_point_cache.include?(key)
      return_point_cache.push key
      pin = get_method_pin(tp.path, tp.lineno, tp.method_id)
      if pin.nil?
        log_cache.push Issue.new(:warning, "Method `#{tp.method_id}` could not be found", tp.method_id, nil, backtrace)
      else
        validate_return pin, tp.return_value, backtrace
      end
    end

    def tracing_file? path
      workspace.has_file?(File.absolute_path(path))
    end

    def get_method_pin path, line, method_name
      source = workspace.source(File.absolute_path(path))
      fragment = source.fragment_at(line, 0)
      source.method_pins.select{|pin| pin.name == method_name.to_s and pin.namespace == fragment.namespace and pin.scope == fragment.scope}.first
    end

    def validate_call pin, tp, backtrace
      if pin.docstring.nil?
        log_cache.push Issue.new(:warning, "#{pin.name} received arguments but does not have param types", pin.name, pin, backtrace) unless variables.empty?
        return
      end
      params = pin.docstring.tags(:param)
      if params.empty?
        log_cache.push Issue.new(:warning, "#{pin.name} received arguments but does not have param types", pin.name, pin, backtrace) unless variables.empty?
        return
      end
      params.each do |param|
        if param.name.empty?
          log_cache.push Issue.new(:warning, "Unnamed parameter(s) in #{pin.path}", pin.name, pin, backtrace) unless variables.empty?
          next
        end
        tag = param.types.first
        if tag.nil?
          log_cache.push Issue.new(:warning, "Parameter `#{param.name}` does not have a type", pin.name, pin, backtrace) unless variables.empty?
          next
        end
        if !tp.binding.local_variables.include?(param.name.to_sym)
          log_cache.push Issue.new(:warning, "Parameter `#{param.name}` does not exist", pin.name, pin, backtrace) unless variables.empty?
          next
        end
        lvar = tp.binding.local_variable_get(param.name.to_sym)
        expected, scope = extract_namespace_and_scope(pin.return_type)
        log_cache.push Issue.new(:error, "`#{pin.path} parameter `#{param.name}` should return #{expected} but returned #{actual}", pin.name, pin, backtrace) unless satisfied?(expected, lvar)
        STDERR.puts "Is #{param.name} in #{variables}?"
      end
    end

    def validate_return pin, value, backtrace
      return if pin.name == 'initialize' and pin.scope == :instance
      pin.resolve api_map
      if pin.return_type.nil?
        # Issue a warning for undefined return types unless the value is nil
        log_cache.push Issue.new(:warning, "`#{pin.path}` does not have a return type and returned #{actual}", pin.name, pin, backtrace) unless value.nil?
      else
        expected, scope = extract_namespace_and_scope(pin.return_type)
        log_cache.push Issue.new(:error, "`#{pin.path}` should return #{pin.return_type} but returned #{actual}", pin.name, pin, backtrace) unless satisfied?(expected, value)
      end
    end

    def satisfied? expected, value
      actual = value.class.to_s
      return if expected == actual
      return if expected == 'Boolean' and (value == true or value == false)
      sup = value.class.superclass
      while expected != sup.to_s
        sup = sup.superclass
        return true if sup.nil?
      end
      false
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
