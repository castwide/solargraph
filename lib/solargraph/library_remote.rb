module Solargraph
  class LibraryRemote < Solargraph::Library
    # @param workspace [Solargraph::Workspace]
    def initialize host
      @host = host
    end

    # @return [Solargraph::Workspace]
    def workspace workspace = nil
      @workspace = workspace unless workspace.nil?
      @workspace
    end

    def api_map
      return @api_map if @api_map
      @api_map = Solargraph::ApiMap.new(@workspace)
      @host.initialized true
      @api_map
    end

    def self.load host, directory
      library = Solargraph::LibraryRemote.new host
      workspace = Solargraph::WorkspaceRemote.new(host, library, directory)
      library.workspace workspace
      library
    end
  end
end
