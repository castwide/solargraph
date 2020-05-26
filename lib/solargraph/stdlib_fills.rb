# frozen_string_literal: true

module Solargraph
  # Overrides for the Ruby stdlib.
  #
  # The YardMap uses this module to add type information to stdlib methods.
  #
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
    }

    # @param path [String]
    # @return [Array<Pin::Reference::Override>]
    def self.get path
      LIBS[path] || []
    end
  end
end
