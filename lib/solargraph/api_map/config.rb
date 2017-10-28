require 'yaml'

module Solargraph
  class ApiMap
    class Config
      # @return [String]
      attr_reader :workspace

      # @return [Array<String>]
      attr_reader :included

      # @return [Array<String>]
      attr_reader :excluded

      # @return [Array<String>]
      attr_reader :domains

      def initialize workspace = nil
        @workspace = workspace
        @included = []
        @excluded = []
        @domains = []
        unless @workspace.nil?
          include_globs = ['**/*.rb']
          exclude_globs = ['spec/**/*', 'test/**/*']
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
            @domains = conf['domains'] || []
          end
          include_globs.each { |g| @included.concat process_glob(g) }
          exclude_globs.each { |g| @excluded.concat process_glob(g) }
        end
      end

      private

      def process_glob glob
        result = []
        Dir[File.join workspace, glob].each do |f|
          result.push File.realdirpath(f)
        end
        result
      end
    end
  end
end
