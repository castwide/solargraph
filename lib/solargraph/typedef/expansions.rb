# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      autoload :Base,              'solargraph/typedef/expansions/base'
      autoload :Block,             'solargraph/typedef/expansions/block'
      autoload :Generics,          'solargraph/typedef/expansions/generics'
      autoload :Inference,         'solargraph/typedef/expansions/inference'
      autoload :Macros,            'solargraph/typedef/expansions/macros'
    end
  end
end
