require 'thread'

module Solargraph
  class Mapper
    def initialize
      @default_api_map = Solargraph::ApiMap.new
      stub = Parser::CurrentRuby.parse(Solargraph::LiveParser.parse(nil))
      @default_api_map.merge(stub)
      @default_api_map.freeze
      @environments = {}
      @semaphore = Mutex.new
    end

    def set filename, code
      Thread.new {
        STDERR.puts "Setting environment..."
        workspace = find_workspace(filename)
        STDERR.puts "Workspace for #{filename} is #{workspace}"
        tmp = CodeMap.new(code, api_map: ApiMap.new(workspace: workspace), with_required: true)
        required = tmp.api_map.required
        current_map = get(filename)
        if current_map.required != required or current_map == @default_api_map
          if workspace.nil?
            cmd = 'solargraph stub-env'
          else
            cmd = 'bundle exec solargraph stub-env'
          end
          if required.any?
            cmd += " --require #{required.join(' ')}"
          end
          stub = nil
          STDERR.puts "Executing #{cmd}"
          Dir.chdir workspace || Dir.pwd do
            #stub = system(cmd)
            stub = `#{cmd}`
          end
          puts stub.class
          unless stub.nil?
            node = Parser::CurrentRuby.parse(stub)
            tmp = ApiMap.new workspace: workspace
            tmp.merge node
            tmp.required.concat required
            tmp.freeze
            @semaphore.synchronize {
              @environments[filename] = tmp
            }
          else
            STDERR.puts "Oops! Null stub"
          end
        end
        STDERR.puts "Done with environment"
      }
    end

    def get filename
      @semaphore.synchronize {
        @environments[filename] || @default_api_map
      }
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
      result
    end
  end
end
