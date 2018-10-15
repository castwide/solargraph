module Solargraph
  module Diagnostics
    # RequireNotFound reports required paths that could not be resolved to
    # either a file in the workspace or a gem.
    #
    class RequireNotFound < Base
      def diagnose source, api_map, config = {}
        result = []
        refs = {}
        map = Solargraph::SourceMap.map(source)
        map.requires.each do |ref|
          refs[ref.name] = ref
        end
        api_map.unresolved_requires.each do |r|
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
