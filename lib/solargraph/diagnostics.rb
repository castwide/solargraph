module Solargraph
  # The Diagnostics library provides reporters for analyzing problems in code
  # and providing the results to language server clients.
  #
  module Diagnostics
    autoload :Base, 'solargraph/diagnostics/base'
    autoload :Severities, 'solargraph/diagnostics/severities'
    autoload :Rubocop, 'solargraph/diagnostics/rubocop'
    autoload :RequireNotFound, 'solargraph/diagnostics/require_not_found'

    # Reporters identified by name for activation in .solargraph.yml files.
    #
    REPORTERS = {
      'rubocop' => Rubocop,
      'require_not_found' => RequireNotFound
    }
  end
end
