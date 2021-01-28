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
        args = ['-f', 'j', filename]
        base_options = RuboCop::Options.new
        options, paths = base_options.parse(args)
        options[:stdin] = code
        [options, paths]
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
