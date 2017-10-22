module Solargraph
  module Pin
    autoload :Base, 'solargraph/pin/base'
    autoload :Method, 'solargraph/pin/method'
    autoload :Attribute, 'solargraph/pin/attribute'
    autoload :BaseVariable, 'solargraph/pin/base_variable'
    autoload :InstanceVariable, 'solargraph/pin/instance_variable'
    autoload :ClassVariable, 'solargraph/pin/class_variable'
    autoload :LocalVariable, 'solargraph/pin/local_variable'
    autoload :Constant, 'solargraph/pin/constant'
    autoload :Symbol, 'solargraph/pin/symbol'
  end
end
