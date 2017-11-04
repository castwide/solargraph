require 'yaml'

module Solargraph
  class ApiMap
    class Config
      attr_reader :workspace
      attr_reader :included
      attr_reader :excluded
      attr_reader :extensions

      def initialize workspace = nil
        @workspace = workspace
        @included = []
        @excluded = []
        @extensions = []
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*']
        unless @workspace.nil?
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
            @extensions = conf['extensions'] || []
          end
        end
        include_globs.each { |g| @included.concat process_glob(g) }
        exclude_globs.each { |g| @excluded.concat process_glob(g) }
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
