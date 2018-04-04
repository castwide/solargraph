module Solargraph
  class Tracer
    def initialize workspace
      @workspace = workspace
      @api_map = Solargraph::ApiMap.new(workspace)
    end

    def self.load directory
      Tracer.new(Solargraph::Workspace.new(directory))
    end

    def run &block
      tracer.enable
      block.call
      tracer.disable
    end

    private

    # @return [Solargraph::Workspace]
    def workspace
      @workspace
    end

    def api_map
      @api_map
    end

    def tracer
      @tracer ||= TracePoint.new(:return) do |tp|
        abspath = File.absolute_path(tp.path)
        if workspace.has_file?(abspath)
          source = workspace.source(abspath)
          fragment = source.fragment_at(tp.lineno, 0)
          pin = api_map.complete(fragment).pins.select{|p| p.name == tp.method_id.to_s}.first
          if pin.nil?
            STDERR.puts "Returning from a method without a pin"
          else
            pin.resolve api_map
            STDERR.puts "This call is expected to return #{pin.return_type}"
            STDERR.puts "And it returns #{tp.return_value.class}"
            # puts caller.inspect
          end
        end
      end
    end
  end
end
