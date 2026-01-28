require 'lint_roller'

module Solargraph
  module LintRoller
    class Plugin < ::LintRoller::Plugin
      # @param config [Hash{String => String}] options passed to the plugin by the user
      def initialize(config)
        config['require_path'] = 'solargraph/rubocop'
        super
      end

      # @sg-ignore Declared return type ::LintRoller::About does not
      #   match inferred type Solargraph::LintRoller::Plugin for
      #   Solargraph::LintRoller::Plugin#about
      # @return [LintRoller::About]
      def about
        # @sg-ignore Unrecognized keyword argument name to Struct.new
        ::LintRoller::About.new(
          name: "solargraph",
          version: Solargraph::VERSION,
          homepage: "https://github.com/castwide/solargraph",
          description: "Configuration of Solargraph typechecking"
        )
      end

      # @sg-ignore Solargraph::LintRoller::Plugin#supported? return
      #   type could not be inferred
      # @param context [LintRoller::Context] provided by the runner
      def supported?(context)
        context.engine == :rubocop
      end

      # @param context [LintRoller::Context] provided by the runner
      #
      # @sg-ignore Declared return type ::LintRoller::Rules does not
      #   match inferred type Solargraph::LintRoller::Plugin for
      #   Solargraph::LintRoller::Plugin#rules
      # @return [LintRoller::Rules]
      def rules(context)
        require 'solargraph/rubocop'

        cwd = __dir__ || '.'

        # @sg-ignore Unrecognized keyword argument type to Struct.new
        ::LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(cwd).join("../../config/default.yml")
        )
      end
    end
  end
end
