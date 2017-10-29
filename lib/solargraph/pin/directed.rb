module Solargraph
  module Pin
    # Directed pins are defined by YARD directives instead of code.
    module Directed
      autoload :Attribute, 'solargraph/pin/directed/attribute'
      autoload :Method,    'solargraph/pin/directed/method'
    end
  end
end
