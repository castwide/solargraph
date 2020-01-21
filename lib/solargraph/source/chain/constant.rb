# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          return [Pin::ROOT_PIN] if word.empty?
          rooted = false
          if word.start_with?('::')
            rooted = true
            bottom = ''
            gates = [word[2..-1].split('::')[0..-2].join('::')]
          else
            bottom = word.split('::')[0..-2].join('::')
            gates = crawl_gates(name_pin)
          end
          result = api_map.get_constants(bottom, *gates)
          result.select{ |p| rooted ? p.path == word[2..-1] : p.path == word || "::#{p.path}" == word || p.path.end_with?("::#{word}") }
        end

        private

        def crawl_gates pin
          clos = pin
          until clos.nil?
            return clos.gates if clos.is_a?(Pin::Namespace)
            clos = clos.closure
          end
          ['']
        end
      end
    end
  end
end
