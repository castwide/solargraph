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
      raise 'Tracer already running' if tracer.enabled?
      if block.nil?
        tracer.enable
      else
        tracer.enable
        block.call
        tracer.disable
      end
    end

    def stop
      raise 'Tracer is not running' unless tracer.enabled?
      tracer.disable
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
    def tracer
      @tracer ||= TracePoint.new(:return) do |tp|
        unless @tracing
          @tracing = true
          key = [tp.path, tp.lineno, tp.return_value.class.to_s]
          unless point_cache.include?(key)
            point_cache.push key
            abspath = File.absolute_path(tp.path)
            if workspace.has_file?(abspath)
              source = workspace.source(abspath)
              fragment = source.fragment_at(tp.lineno - 1, 0)
              pin = source.method_pins.select{|pin| pin.name == tp.method_id.to_s and pin.namespace == fragment.namespace and pin.scope == fragment.scope}.first
              if pin.nil?
                log_cache.push Issue.new(:warning, "Method `#{tp.method_id}` could not be found", tp.method_id, nil, tp.return_value.class.to_s, caller)
              else
                analyze pin, tp.return_value, caller
              end
            end
          end
          @tracing = false
        end
      end
    end

    def analyze pin, value, backtrace
      return if pin.name == 'initialize' and pin.scope == :instance
      actual = value.class.to_s
      pin.resolve api_map
      if pin.return_type.nil?
        log_cache.push Issue.new(:warning, "`#{pin.path}` does not have a return type and returned #{actual}", pin.name, nil, actual, backtrace)
      elsif pin.return_type != actual
        log_cache.push Issue.new(:error, "`#{pin.path}` should return #{pin.return_type} but returned #{actual}", pin.name, pin.return_type, actual, backtrace)
      end
    end
  end
end
