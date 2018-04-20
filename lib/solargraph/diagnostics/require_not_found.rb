module Solargraph
  module Diagnostics
    class RequireNotFound < Base
      def diagnose source, api_map
        result = []
        refs = {}
        source.requires.each do |ref|
          refs[ref.name] = ref
        end
        api_map.yard_map.unresolved_requires.each do |r|
          next unless refs.has_key?(r)
          result.push(
            range: refs[r].location.range.to_hash,
            severity: Diagnostics::Severities::WARNING,
            source: 'Solargraph',
            message: "Required path #{r} could not be resolved."
          )
        end
        result
      end
    end
  end
end
