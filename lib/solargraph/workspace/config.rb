require 'yaml'

module Solargraph
  class Workspace
    class Config
      # @return [String]
      attr_reader :workspace

      # @return [Hash]
      attr_reader :raw_data

      # @param workspace [String]
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
        @raw_data['require'] ||= []
        @raw_data['domains'] ||= []
        @raw_data['reporters'] ||= []
        @raw_data['plugins'] ||= []
        included
        excluded
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
        @excluded ||= process_exclusions(@raw_data['exclude'])
      end

      # The calculated array of (included - excluded) files in the workspace.
      #
      # @return [Array<String>]
      def calculated
        @calculated ||= included - excluded
      end

      # @return [Array<String>]
      def domains
        raw_data['domains']
      end

      def required
        raw_data['require']
      end

      def plugins
        raw_data['plugins']
      end

      def reporters
        raw_data['reporters']
      end

      private

      def process_globs globs
        result = []
        globs.each do |glob|
          Dir[File.join workspace, glob].each do |f|
            result.push File.realdirpath(f).gsub(/\\/, '/')
          end
        end
        result
      end

      def process_exclusions globs
        remainder = globs.select do |glob|
          if glob_is_directory?(glob)
            exdir = File.realdirpath(File.join(workspace, glob_to_directory(glob)))
            included.delete_if { |file| file.start_with?(exdir) }
            false
          else
            true
          end
        end
        process_globs remainder
      end

      def glob_is_directory? glob
        File.directory?(glob) or File.directory?(glob_to_directory(glob))
      end

      def glob_to_directory glob
        glob.gsub(/(\/\*|\/\*\*\/\*\*?)$/, '')
      end
    end
  end
end
