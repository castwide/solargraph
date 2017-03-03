module Solargraph
  class Mapper
    def initialize
      @default_api_map = Solargraph::ApiMap.new
      stub = Parser::CurrentRuby.parse(Solargraph::LiveParser.parse(nil))
      @default_api_map.merge(stub)
      @default_api_map.freeze
      @require_nodes = {}
    end

    def get filename, text
      workspace = find_workspace(filename)
      STDERR.puts "Building with #{text}"
      CodeMap.new(text, api_map: @default_api_map, workspace: workspace, require_nodes: @require_nodes)
    end

    def find_workspace filename
      dirname = filename
      lastname = nil
      result = nil
      until dirname == lastname
        if File.file?("#{dirname}/Gemfile")
          result = dirname
          break
        end
        lastname = dirname
        dirname = File.dirname(dirname)
      end
      result || File.dirname(filename)
    end
  end
end
