module Solargraph
  class Bundle
    # @return [Array<Source>]
    attr_reader :sources

    # @return [Array<String>]
    attr_reader :required

    # @return [Array<String>]
    attr_reader :load_paths

    # @return [YardMap]
    attr_reader :yard_map

    def initialize sources: [], required: [], load_paths: [], yard_map: YardMap.new
      @sources = sources
      @required = required
      @load_paths = load_paths
      @yard_map = yard_map
    end
  end
end
