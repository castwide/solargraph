# frozen_string_literal: true

module Solargraph
  module Diagnostics
    # Utility methods for the RuboCop diagnostics reporter.
    #
    module RubocopHelpers
      module_function

      # Generate command-line options for the specified filename and code.
      #
      # @param filename [String]
      # @param code [String]
      # @return [Array(Array<String>, Array<String>)]
      def generate_options filename, code
        args = ['-f', 'j']
        rubocop_file = find_rubocop_file(filename)
        args.push('-c', fix_drive_letter(rubocop_file)) unless rubocop_file.nil?
        args.push filename
        options, paths = RuboCop::Options.new.parse(args)
        options[:stdin] = code
        [options, paths]
      end

      # Find a RuboCop configuration file in a file's directory tree.
      #
      # @param filename [String]
      # @return [String, nil]
      def find_rubocop_file filename
        dir = File.dirname(filename)
        until File.dirname(dir) == dir
          here = File.join(dir, '.rubocop.yml')
          return here if File.exist?(here)
          dir = File.dirname(dir)
        end
        nil
      end

      # RuboCop internally uses capitalized drive letters for Windows paths,
      # so we need to convert the paths provided to the command.
      #
      # @param path [String]
      # @return [String]
      def fix_drive_letter path
        return path unless path.match(/^[a-z]:/)
        path[0].upcase + path[1..-1]
      end

      # @todo This is a smelly way to redirect output, but the RuboCop specs do
      #   the same thing.
      # @return [String]
      def redirect_stdout
        redir = StringIO.new
        $stdout = redir
        yield if block_given?
        $stdout = STDOUT
        redir.string
      end
    end
  end
end
