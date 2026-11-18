# frozen_string_literal: true

# A Solargraph plugin whose convention adds a pin to every file it maps,
# including the files of gems being cached
module SolargraphCacheProbePlugin
  class Convention < Solargraph::Convention::Base
    def local source_map
      location = Solargraph::Location.new(source_map.filename, Solargraph::Range.from_to(0, 0, 0, 0))
      pin = Solargraph::Pin::Method.new(name: 'cache_probe_plugin_method', closure: Solargraph::Pin::ROOT_PIN,
                                        location: location, source: :cache_probe_plugin)
      Solargraph::Environ.new(pins: [pin])
    end
  end
end

Solargraph::Convention.register SolargraphCacheProbePlugin::Convention
