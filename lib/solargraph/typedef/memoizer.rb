# frozen_string_literal: true

module Solargraph
  module Typedef
    module Memoizer
      autoload :Cache, 'solargraph/typedef/memoizer/cache'
      autoload :Key,   'solargraph/typedef/memoizer/key'
      autoload :Memo,  'solargraph/typedef/memoizer/memo'
    end
  end
end
