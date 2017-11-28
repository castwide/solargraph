require 'yaml'

module Solargraph
  class ApiMap
    class Config
      # @return [String]
      attr_reader :workspace

      # @return [Hash]
      attr_reader :raw_data

      def initialize workspace = nil
        @workspace = workspace
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*']
        unless @workspace.nil?
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            @raw_data = YAML.load(File.read(sfile))
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
          end
        end
        @raw_data ||= {}
        @raw_data['include'] ||= include_globs
        @raw_data['exclude'] ||= exclude_globs
        @raw_data['domains'] ||= []
        @raw_data['required'] ||= []
      end

      # An array of files included in the workspace (before calculating excluded files).
      #
      # @return [Array<String>]
      def included
        return [] if workspace.nil?
        @included ||= process_globs(@raw_data['include'])
      end

      # An array of files excluded from the workspace.
      # 
      # @return [Array<String>]
      def excluded
        return [] if workspace.nil?
        @excluded ||= process_globs(@raw_data['exclude'])
      end

      # The calculated array of (included - excluded) files in the workspace.
      #
      # @return [Array<String>]
      def calculated
        @calculated ||= (included - excluded)
      end

      # @return [Array<String>]
      def domains
        raw_data['domains']
      end

      def required
        raw_data['required']
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
