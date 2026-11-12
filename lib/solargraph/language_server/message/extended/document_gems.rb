# frozen_string_literal: true

require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update YARD documentation for installed gems. If the `rebuild`
        # parameter is true, rebuild existing yardocs.
        #
        class DocumentGems < Base
          def process
            statuses = commands_by_workspace.map { |cmd| Open3.capture2(*cmd).last }
            if statuses.all?(&:success?)
              set_result({
                           status: 'ok'
                         })
            else
              host.show_message 'An error occurred while building gem documentation.', LanguageServer::MessageTypes::ERROR
              set_result({
                           status: 'err'
                         })
            end
          end

          private

          # One command per workspace, so each caches its gems in the
          # directory for its own plugins.
          #
          # @return [Array<Array<String>>] the argv of one `solargraph gems`
          #   command for each workspace with a directory, or of a single
          #   command without --directory when there is none
          def commands_by_workspace
            cmd = [host.command_path, 'gems']
            cmd.push '--rebuild' if params['rebuild']
            workspaces = host.libraries.map(&:workspace).reject { |workspace| ['', '*'].include?(workspace.directory) }
            return [cmd] if workspaces.empty?

            workspaces.map do |workspace|
              cmd + ['--directory', workspace.directory,
                     "--plugins=#{workspace.plugins.join(File::PATH_SEPARATOR)}"]
            end
          end
        end
      end
    end
  end
end
