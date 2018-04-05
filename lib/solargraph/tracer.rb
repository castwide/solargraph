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
    end

    private

    def log_cache
      @log_cache ||= []
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
          abspath = File.absolute_path(tp.path)
          if workspace.has_file?(abspath)
            actual = tp.return_value.class.to_s
            source = workspace.source(abspath)
            fragment = source.fragment_at(tp.lineno, 0)
            pin = api_map.complete(fragment).pins.select{|p| p.name == tp.method_id.to_s}.first
            if pin.nil?
              log_cache.push Issue.new(:warning, "Method `#{tp.method_id}` could not be found", tp.method_id, nil, actual, caller)
            else
              pin.resolve api_map
              expected = pin.return_type
              if expected.nil?
                log_cache.push Issue.new(:warning, "`#{pin.path}` does not have a return type", tp.method_id, nil, actual, caller)
              elsif expected != actual
                log_cache.push Issue.new(:error, "`#{pin.path}` should return #{expected} but returned #{actual}", tp.method_id, expected, actual, caller)
              end
            end
          end
          @tracing = false
        end
      end
    end
  end
end
