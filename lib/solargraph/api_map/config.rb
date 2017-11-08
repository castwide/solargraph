require 'yaml'

module Solargraph
  class ApiMap
    class Config
      attr_reader :workspace
      attr_reader :raw_data

      def initialize workspace = nil
        @workspace = workspace
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*']
        unless @workspace.nil?
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            @raw_data = YAML.load(File.read(sfile))
          end
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
