module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          return [Pin::ROOT_PIN] if word.empty?
          if word.start_with?('::')
            context = ''
            bottom = word[2..-1]
          else
            context = name_pin.full_context.namespace
            bottom = word
          end
          if bottom.include?('::')
            ns = bottom.split('::')[0..-2].join('::')
          else
            ns = ''
          end
          result = api_map.get_constants(ns, context)
          last_name = bottom.split('::').last
          result.select{ |p| p.name == last_name }
        end
      end
    end
  end
end
