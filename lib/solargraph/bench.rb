# frozen_string_literal: true

module Solargraph
  # An aggregation of a workspace and additional sources to be cataloged in an
  # ApiMap.
  #
  class Bench
    # @return [Workspace]
    attr_reader :workspace

    # @return [Array<Source>]
    attr_reader :opened

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @param workspace [Workspace]
    # @param opened [Array<Source>]
    def initialize workspace: Workspace.new, opened: [], pins: []
      @workspace = workspace
      @opened = opened
      @pins = pins
    end

    # @return [Array<Source>]
    def sources
      @sources ||= (opened + workspace.sources).uniq(&:filename)
    end
  end
end
