module Solargraph
  module Diagnostics
    class UpdateErrors < Base
      def diagnose source, api_map
        result = []
        source.error_ranges.each do |range|
          result.push(
            range: range.to_hash,
            severity: Diagnostics::Severities::ERROR,
            source: 'Solargraph',
            message: 'Syntax error'
          )
        end
        result
      end
    end
  end
end
