module Solargraph
  class Bundle
    # @return [Workspace]
    attr_reader :workspace

    # @return [Array<Source>]
    attr_reader :opened

    # @param workspace [Workspace]
    # @param opened [Array<Source>]
    def initialize workspace: Workspace.new, opened: []
      @workspace = workspace
      @opened = opened
    end

    # @return [Array<Source>]
    def sources
      @sources ||= (opened + workspace.sources).uniq(&:filename)
    end
  end
end
