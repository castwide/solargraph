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
          if word.start_with?('::')
            base = word[2..-1]
            gates = ['']
          else
            base = word
            gates = crawl_gates(name_pin)
          end
          pins = []
          gates.each do |gate|
            type = ComplexType::UNDEFINED
            parts = base.split('::')
            # Use deep inference to resolve root constants
            parts[0..-2].each do |sym|
              fqns = if type.undefined?
                if gate.empty?
                  sym
                else
                  "#{gate}::#{sym}"
                end
              else
                "#{type.namespace}::#{sym}"
              end
              pins.replace api_map.get_path_pins(fqns)
              break if pins.empty?
              pins.each do |pin|
                type = pin.typify(api_map)
                break if type.defined?
                type = pin.probe(api_map)
                break if type.defined?
              end
              if type.undefined?
                pins.clear
                break
              end
            end
            # Return the last constant's pins, even if they're undefined
            sym = parts.last
            fqns = if type.undefined?
              if gate.empty?
                sym
              else
                "#{gate}::#{sym}"
              end
            else
              "#{type.namespace}::#{sym}"
            end
            pins.replace api_map.get_path_pins(fqns)
            return pins unless pins.empty?
          end
          pins
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
