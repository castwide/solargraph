module Solargraph
  class WorkspaceRemote < Solargraph::Workspace

  	autoload :ConfigRemote, 'solargraph/workspace_remote/config_remote'

    # @param directory [String]
    def initialize host, library, directory = nil
      @host = host
      @library = library
      @directory = directory
      @directory = nil if @directory == ''
      load_file_list unless @directory.nil?
    end

    # @return [Solargraph::Workspace::Config]
    def config files = nil
      @config = Solargraph::WorkspaceRemote::ConfigRemote.new(@directory, files) if @config.nil? or !files.nil?
      @config
    end

    def load_file_list
      @host.send_request "workspace/xfiles", {'base' => "file://#{@directory}"} do |response|
        files = []
        response.each do |file|
          files.push file['uri']
        end
        config files
        load_sources
      end
    end

    def load_sources
      source_hash.clear
      unless directory.nil?
        size = config.calculated.length
        if size == 0
          @host.initialized true
          return
        end
        raise WorkspaceTooLargeError.new(size, config.max_files) if config.max_files > 0 and size > config.max_files
        loaded = 0
        config.calculated.each do |fileuri|
          @host.send_request "textDocument/xcontent", {'textDocument' => {'uri' => fileuri}} do |response|
            filename = fileuri.gsub(/^[^:]+:\/\//, "")
            source_hash[filename] = Solargraph::SourceRemote.load_string(response['text'], filename)
            loaded += 1
            if loaded == size and !@host.initialized
              @library.api_map
            end
          end
        end
      end
      @stime = Time.now
    end

  end
end