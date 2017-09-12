require 'yaml'

module Solargraph
  class ApiMap
    class Config
      attr_reader :workspace
      attr_reader :included
      attr_reader :excluded

      def initialize workspace = nil
        @workspace = workspace
        @included = []
        @excluded = []
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*']
        unless @workspace.nil?
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
          end
        end
        include_globs.each { |g| @included.concat process_glob(g) }
        exclude_globs.each { |g| @excluded.concat process_glob(g) }
      end

      private

      def process_glob glob
        result = []
        Dir[glob].each do |f|
          result.push File.realdirpath(f)
        end
        result
      end
    end
  end
end
