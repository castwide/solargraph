require 'yaml'

module Solargraph
  class ApiMap
    class Config
      # @return [String]
      attr_reader :workspace
      attr_reader :raw_data

      # @return [Array<String>]
      attr_reader :included

      # @return [Array<String>]
      attr_reader :excluded

      # @return [Array<String>]
      attr_reader :domains

      def initialize workspace = nil
        @workspace = workspace
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*']
        @included = []
        @excluded = []
        @domains = []
        unless @workspace.nil?
          include_globs = ['**/*.rb']
          exclude_globs = ['spec/**/*', 'test/**/*']
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            @raw_data = YAML.load(File.read(sfile))
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
            @domains = conf['domains'] || []
          end
          @included.concat process_globs(include_globs)
          @excluded.concat process_globs(exclude_globs)
        end
        @raw_data ||= {}
        @raw_data['include'] = @raw_data['include'] || include_globs
        @raw_data['exclude'] = @raw_data['exclude'] || exclude_globs
      end

      def included
        process_globs @raw_data['include']
      end

      def excluded
        process_globs @raw_data['exclude']
      end

      private

      def process_globs globs
        result = []
        globs.each do |glob|
          Dir[File.join workspace, glob].each do |f|
            result.push File.realdirpath(f)
          end
        end
        result
      end
    end
  end
end
