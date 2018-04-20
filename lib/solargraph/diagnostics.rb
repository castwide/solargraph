module Solargraph
  module Diagnostics
    autoload :Base, 'solargraph/diagnostics/base'
    autoload :Severities, 'solargraph/diagnostics/severities'
    autoload :Rubocop, 'solargraph/diagnostics/rubocop'
    autoload :RequireNotFound, 'solargraph/diagnostics/require_not_found'

    REPORTERS = {
      'rubocop' => Rubocop,
      'require_not_found' => RequireNotFound
    }
  end
end
