# frozen_string_literal: true

module Solargraph
  module Convention
    # Stdlib convention
    #
    class Stdlib < Base
      def global api_map
        result = []
        # @todo Lots of visibility boundaries crossed here. Refactor for cleanliness.
        api_map.required.each do |path|
          result.concat StdlibFills.get(path)
        end
        Environ.new(
          pins: result
        )
      end

      module StdlibFills
        Override = Pin::Reference::Override

        LIBS = {
          'benchmark' => [
            Override.method_return('Benchmark.measure', 'Benchmark::Tms')
          ],

          'pathname' => [
            Override.method_return('Pathname#join', 'Pathname'),
            Override.method_return('Pathname#basename', 'Pathname'),
            Override.method_return('Pathname#dirname', 'Pathname'),
            Override.method_return('Pathname#cleanpath', 'Pathname'),
            Override.method_return('Pathname#children', 'Array<Pathname>'),
            Override.method_return('Pathname#entries', 'Array<Pathname>')
          ],

          'set' => [
            Override.method_return('Enumerable#to_set', 'Set'),
            Override.method_return('Set#add', 'self'),
            Override.method_return('Set#add?', 'self, nil'),
            Override.method_return('Set#classify', 'Hash'),
            Override.from_comment('Set#each', '@yieldparam_single_parameter')
          ]
        }.freeze

        # @param path [String]
        # @return [Array<Pin::Reference::Override>]
        def self.get path
          LIBS[path] || []
        end
      end
    end
  end
end
